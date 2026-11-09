--!nonstrict

-- Hyprland-only keybind data service.
--
-- The active configuration is parsed once during startup and again after
-- a relevant settings change or explicit refresh request. There is no
-- update interval, filesystem watcher, polling loop, or persistent
-- subprocess.

local noctalia = noctalia
if noctalia == nil then
  local host = require("./tests/host_mock")
  noctalia = host.noctalia
end

local SNAPSHOT_KEY = "hypr-cheatsheet.snapshot"
local REFRESH_REQUEST_KEY = "hypr-cheatsheet.refresh-request"
local SELF_TEST_REQUEST_KEY = "hypr-cheatsheet.self-test-request"
local HYPR_STEP_KEY = "hypr-cheatsheet.hypr-step"

local MAX_PARSE_DEPTH = 32
local MAX_PARSE_FILES = 256

local BINDINGS_CACHE_FILE = "bindings-cache.json"
local CACHE_SCHEMA = 1

local HYPR_BINDING_SLICE = 16

local refreshing = false
local refreshQueued = false
local refreshGeneration = 0
local lastGood = nil

local hyprJob = nil
local hyprStepCounter = 0

local function tr(key, values)
  return noctalia.tr(key, values)
end

local function trim(value)
  local result = (value or ""):gsub("^%s+", ""):gsub("%s+$", "")
  return result
end

local function startsWith(value, prefix)
  return value:sub(1, #prefix) == prefix
end

local function configString(key, fallback)
  local value = noctalia.getConfig(key)
  if type(value) ~= "string" or trim(value) == "" then
    return fallback
  end
  return trim(value)
end

local function pathDirname(path)
  local clean = (path or ""):gsub("/+$", "")
  local parent = clean:match("^(.*)/[^/]*$")

  if parent == nil or parent == "" then
    return clean:sub(1, 1) == "/" and "/" or "."
  end

  return parent
end

local function pathJoin(base, child)
  if child == nil or child == "" then
    return base
  end

  if child:sub(1, 1) == "/" then
    return child
  end

  if base == "/" then
    return "/" .. child
  end

  return (base:gsub("/+$", "")) .. "/" .. child
end

local function normalizePath(path)
  local absolute = path:sub(1, 1) == "/"
  local parts = {}

  for part in path:gmatch("[^/]+") do
    if part == ".." then
      if #parts > 0 and parts[#parts] ~= ".." then
        table.remove(parts)
      elseif not absolute then
        table.insert(parts, part)
      end
    elseif part ~= "." and part ~= "" then
      table.insert(parts, part)
    end
  end

  local result = table.concat(parts, "/")

  if absolute then
    result = "/" .. result
  end

  if result == "" then
    return absolute and "/" or "."
  end

  return result
end

local function expandEnvironment(path)
  local expanded = path:gsub("%${([%w_]+)}", function(name)
    return noctalia.getenv(name) or "${" .. name .. "}"
  end)

  expanded = expanded:gsub("%$HOME", noctalia.getenv("HOME") or "~")

  return noctalia.expandPath(expanded)
end

local function unquote(value)
  local result = trim(value)

  if #result >= 2 then
    local first = result:sub(1, 1)
    local last = result:sub(-1)

    if (first == "\"" and last == "\"")
      or (first == "'" and last == "'")
    then
      result = result:sub(2, -2)
    end
  end

  return result
end

local function resolvePath(value, includingFile)
  local path = expandEnvironment(unquote(value))

  if path:sub(1, 1) ~= "/" then
    path = pathJoin(pathDirname(includingFile), path)
  end

  return normalizePath(path)
end

local function hasGlob(path)
  return path:find("*", 1, true) ~= nil
    or path:find("?", 1, true) ~= nil
    or path:find("[", 1, true) ~= nil
end

local LUA_PATTERN_MAGIC = {
  ["^"] = true,
  ["$"] = true,
  ["("] = true,
  [")"] = true,
  ["%"] = true,
  ["."] = true,
  ["+"] = true,
  ["-"] = true,
  ["]"] = true,
}

local function globPattern(segment)
  local result = { "^" }
  local index = 1

  while index <= #segment do
    local char = segment:sub(index, index)

    if char == "*" then
      table.insert(result, ".*")
    elseif char == "?" then
      table.insert(result, ".")
    elseif char == "[" then
      local closing = segment:find("]", index + 1, true)

      if closing ~= nil then
        table.insert(result, segment:sub(index, closing))
        index = closing
      else
        table.insert(result, "%[")
      end
    elseif LUA_PATTERN_MAGIC[char] then
      table.insert(result, "%" .. char)
    else
      table.insert(result, char)
    end

    index += 1
  end

  table.insert(result, "$")

  return table.concat(result)
end

local function expandGlob(path, context)
  if not hasGlob(path) then
    return { path }
  end

  local candidates = {
    path:sub(1, 1) == "/" and "/" or ".",
  }

  for segment in path:gmatch("[^/]+") do
    local nextCandidates = {}

    if hasGlob(segment) then
      local pattern = globPattern(segment)

      for _, base in ipairs(candidates) do
        local entries = noctalia.listDir(base)

        if entries ~= nil then
          table.sort(entries)

          for _, name in ipairs(entries) do
            if name:match(pattern) then
              table.insert(
                nextCandidates,
                normalizePath(pathJoin(base, name))
              )
            end
          end
        end
      end
    else
      for _, base in ipairs(candidates) do
        table.insert(
          nextCandidates,
          normalizePath(pathJoin(base, segment))
        )
      end
    end

    candidates = nextCandidates
  end

  local files = {}

  for _, candidate in ipairs(candidates) do
    local info = noctalia.fileInfo(candidate)

    if info ~= nil and not info.isDir then
      table.insert(files, candidate)
    end
  end

  table.sort(files)

  if context ~= nil and hasGlob(path) then
    local snapshot = {}

    for _, file in ipairs(files) do
      table.insert(snapshot, file)
    end

    table.insert(
      context.globs,
      {
        pattern = path,
        files = snapshot,
      }
    )
  end

  return files
end

local function extractTrailingDescription(line)
  local ending = line:sub(-1)
  local startIndex
  local description

  if ending == "\"" then
    startIndex, _, description =
      line:find("#%s*\"([^\"]*)\"%s*$")
  elseif ending == "'" then
    startIndex, _, description =
      line:find("#%s*'([^']*)'%s*$")
  end

  if startIndex == nil then
    return line, ""
  end

  return trim(line:sub(1, startIndex - 1)), trim(description)
end

local function splitCsv(value, maximumParts)
  if value:find("\"", 1, true) == nil
    and value:find("'", 1, true) == nil
    and value:find("\\", 1, true) == nil
  then
    local parts = {}
    local startIndex = 1

    while maximumParts == nil or #parts < maximumParts - 1 do
      local comma = value:find(",", startIndex, true)

      if comma == nil then
        break
      end

      table.insert(
        parts,
        trim(value:sub(startIndex, comma - 1))
      )

      startIndex = comma + 1
    end

    table.insert(parts, trim(value:sub(startIndex)))

    return parts
  end

  local parts = {}
  local current = {}
  local quote = nil
  local escaped = false
  local index = 1

  while index <= #value do
    local char = value:sub(index, index)

    if escaped then
      table.insert(current, char)
      escaped = false
    elseif char == "\\" and quote ~= nil then
      table.insert(current, char)
      escaped = true
    elseif quote ~= nil then
      table.insert(current, char)

      if char == quote then
        quote = nil
      end
    elseif char == "\"" or char == "'" then
      quote = char
      table.insert(current, char)
    elseif char == ","
      and (maximumParts == nil or #parts < maximumParts - 1)
    then
      table.insert(parts, trim(table.concat(current)))
      current = {}
    else
      table.insert(current, char)
    end

    index += 1
  end

  table.insert(parts, trim(table.concat(current)))

  return parts
end

local MODIFIER_ORDER = {
  "SUPER",
  "CTRL",
  "SHIFT",
  "ALT",
  "MOD2",
  "MOD3",
  "MOD5",
}

local KNOWN_MODIFIERS = {
  SUPER = true,
  CTRL = true,
  SHIFT = true,
  ALT = true,
  MOD2 = true,
  MOD3 = true,
  MOD5 = true,
}

local MODIFIER_ALIASES = {
  LOGO = "SUPER",
  WIN = "SUPER",
  MOD4 = "SUPER",
  CONTROL = "CTRL",
  MOD1 = "ALT",
}

local function expandHyprVariables(value, variables)
  local previous = value

  for _ = 1, 8 do
    local expanded = previous:gsub(
      "%$([%w_]+)",
      function(name)
        return variables[name] or "$" .. name
      end
    )

    if expanded == previous then
      break
    end

    previous = expanded
  end

  return previous
end

local function normalizeModifiers(value, variables)
  local raw = expandHyprVariables(value or "", variables or {})

  raw = raw
    :gsub("%+", " ")
    :gsub("|", " ")
    :gsub(",", " ")

  local present = {}
  local unknown = {}

  for token in raw:gmatch("[^%s]+") do
    local upper = string.upper(token)
    upper = MODIFIER_ALIASES[upper] or upper

    if upper ~= "NONE" and upper ~= "" then
      if KNOWN_MODIFIERS[upper] then
        present[upper] = true
      elseif not present[upper] then
        present[upper] = true
        table.insert(unknown, upper)
      end
    end
  end

  local result = {}

  for _, name in ipairs(MODIFIER_ORDER) do
    if present[name] then
      table.insert(result, name)
    end
  end

  for _, name in ipairs(unknown) do
    table.insert(result, name)
  end

  return result
end

local function parseDescription(value)
  local description = trim(value)

  if description == "" then
    return "Other", ""
  end

  local category, cleanDescription =
    description:match("^%[([^%]]+)%]%s*(.-)%s*$")

  if category ~= nil then
    category = trim(category)
    cleanDescription = trim(cleanDescription)

    if category ~= "" and cleanDescription ~= "" then
      return category, cleanDescription
    end
  end

  return "Other", description
end

local function bindingIdentity(binding)
  return table.concat({
    "hyprland",
    binding.bindingType or "",
    table.concat(binding.modifiers or {}, "+"),
    binding.key or "",
    binding.action or "",
    binding.submap or "",
  }, "|")
end

local function addBinding(target, binding)
  local category, description =
    parseDescription(binding.description)

  binding.category = category
  binding.baseCategory = category
  binding.description = description
  binding.action = trim(binding.action)
  binding.key = trim(binding.key)
  binding.modifiers = binding.modifiers or {}
  binding.compositor = "hyprland"
  binding.id = bindingIdentity(binding)

  table.insert(target, binding)
end

local function parseHyprContent(content, sourceFile, context)
  local includes = {}
  local variables = context.variables
  local lineNumber = 0

  for rawLine in (content .. "\n"):gmatch("(.-)\r?\n") do
    lineNumber += 1

    local line = trim(rawLine)

    if line ~= "" then
      local variable, value =
        line:match("^%$([%w_]+)%s*=%s*(.-)%s*$")

      local sourcePath =
        line:match("^source%s*=%s*(.-)%s*$")

      if variable ~= nil then
        variables[variable] = value

      elseif sourcePath ~= nil then
        table.insert(
          includes,
          {
            path = expandHyprVariables(
              sourcePath,
              variables
            ),
            optional = false,
          }
        )

      else
        local clean, description =
          extractTrailingDescription(line)

        local directive, body =
          clean:match("^(bind[%a]*)%s*=%s*(.*)$")

        if directive ~= nil then
          local fields = splitCsv(body, 4)

          local key = fields[2] or ""
          local dispatcher = fields[3] or ""

          if key ~= "" and dispatcher ~= "" then
            addBinding(context.bindings, {
              bindingType = string.lower(directive),
              modifiers = normalizeModifiers(
                fields[1],
                variables
              ),
              key = key,
              action = trim(
                dispatcher
                  .. " "
                  .. (fields[4] or "")
              ),
              description = description,
              sourceFile = sourceFile,
              sourceLine = lineNumber,
              submap = "",
            })
          end
        end
      end
    end
  end

  return includes
end

local function walkConfig(rootPath, parser)
  local context = {
    bindings = {},
    variables = {},
    warnings = {},
    visited = {},
    fileCount = 0,
    rootRead = false,
    sources = {},
    globs = {},
  }

  local visit

  visit = function(pattern, depth, optional, isRoot)
    if depth > MAX_PARSE_DEPTH then
      table.insert(
        context.warnings,
        "Include depth exceeded at " .. pattern
      )
      return
    end

    if context.fileCount >= MAX_PARSE_FILES then
      table.insert(
        context.warnings,
        "File limit reached at " .. pattern
      )
      return
    end

    local files = expandGlob(pattern, context)

    if #files == 0 then
      if not optional then
        table.insert(
          context.warnings,
          "Could not read " .. pattern
        )
      end

      return
    end

    for _, file in ipairs(files) do
      file = normalizePath(file)

      if not context.visited[file]
        and context.fileCount < MAX_PARSE_FILES
      then
        context.visited[file] = true
        context.fileCount += 1

        local content, err =
          noctalia.readFile(file)

        if content == nil then
          if not optional then
            table.insert(
              context.warnings,
              err or ("Could not read " .. file)
            )
          end
        else
          local info = noctalia.fileInfo(file)

          if info ~= nil then
            table.insert(
              context.sources,
              {
                path = file,
                size = info.size,
                mtime = info.mtime,
              }
            )
          end

          if isRoot then
            context.rootRead = true
          end

          local includes =
            parser(content, file, context) or {}

          for _, include in ipairs(includes) do
            local resolved =
              resolvePath(include.path, file)

            visit(
              resolved,
              depth + 1,
              include.optional == true,
              false
            )
          end
        end
      end
    end
  end

  local expandedRoot =
    normalizePath(expandEnvironment(rootPath))

  visit(expandedRoot, 0, false, true)

  return context
end

local function readConfig(rootPath, parser)
  local context =
    walkConfig(rootPath, parser)

  if not context.rootRead then
    context =
      walkConfig(rootPath, parser)
  end

  if not context.rootRead then
    noctalia.log(
      "Hypr cheatsheet could not read "
        .. expandEnvironment(rootPath)
        .. ": "
        .. table.concat(context.warnings, "; ")
    )
  end

  return context
end

local function modifiersFromMask(mask)
  local result = {}

  local bits = {
    { 1, "SHIFT" },
    { 4, "CTRL" },
    { 8, "ALT" },
    { 16, "MOD2" },
    { 32, "MOD3" },
    { 64, "SUPER" },
    { 128, "MOD5" },
  }

  mask = tonumber(mask) or 0

  for _, entry in ipairs(bits) do
    if math.floor(mask / entry[1]) % 2 == 1 then
      table.insert(result, entry[2])
    end
  end

  return result
end

local function hyprBindingFromEntry(entry)
  if type(entry) ~= "table" then
    return nil
  end

  local description =
    entry.has_description == false
      and ""
      or (entry.description or "")

  local key = entry.key or ""

  if key == ""
    and tonumber(entry.keycode) ~= nil
    and tonumber(entry.keycode) ~= 0
  then
    key = "code:" .. tostring(entry.keycode)
  end

  local dispatcher = entry.dispatcher or ""
  local argument = entry.arg or ""

  if key == "" or dispatcher == "" then
    return nil
  end

  local binding = {
    bindingType =
      entry.mouse == true
        and "bindm"
        or "bind",

    modifiers =
      modifiersFromMask(entry.modmask),

    key = key,

    action = trim(
      dispatcher .. " " .. argument
    ),

    description = description,

    sourceFile = "hyprctl binds -j",
    sourceLine = 0,

    submap = entry.submap or "",
  }

  addBinding({}, binding)

  return binding
end

local function parseHyprJsonEntries(raw)
  local decoded, err =
    noctalia.json.decode(raw)

  if type(decoded) ~= "table" then
    return nil, err or "Invalid hyprctl JSON"
  end

  return decoded, nil
end

local function parseHyprJson(raw)
  local decoded, err =
    parseHyprJsonEntries(raw)

  if decoded == nil then
    return nil, err
  end

  local result = {}

  for _, entry in ipairs(decoded) do
    local binding =
      hyprBindingFromEntry(entry)

    if binding ~= nil then
      table.insert(result, binding)
    end
  end

  return result, nil
end

local function currentRequest()
  local configType =
    configString("config_type", "lua")

  local root =
    configString(
      "config",
      "~/.config/hypr/hyprland.lua"
    )

  if configType ~= "lua"
    and configType ~= "hyprlang"
  then
    return nil
  end

  return {
    parser = configType,
    root = normalizePath(
      expandEnvironment(root)
    ),
  }
end

local function requestsMatch(left, right)
  return type(left) == "table"
    and type(right) == "table"
    and left.parser == right.parser
    and left.root == right.root
end

local function normalizedCache(decoded)
  if type(decoded) ~= "table"
    or decoded.schema ~= CACHE_SCHEMA
    or type(decoded.request) ~= "table"
    or type(decoded.bindings) ~= "table"
    or type(decoded.sources) ~= "table"
    or type(decoded.globs) ~= "table"
  then
    return nil
  end

  local cachedBindings = {}

  for _, item in ipairs(decoded.bindings) do
    if type(item) ~= "table"
      or type(item.key) ~= "string"
      or type(item.action) ~= "string"
      or type(item.modifiers) ~= "table"
    then
      return nil
    end

    local modifiers = {}

    for _, modifier in ipairs(item.modifiers) do
      if type(modifier) ~= "string" then
        return nil
      end

      table.insert(modifiers, modifier)
    end

    addBinding(cachedBindings, {
      bindingType =
        type(item.bindingType) == "string"
          and item.bindingType
          or "bind",

      modifiers = modifiers,

      key = item.key,

      action = item.action,

      description =
        type(item.description) == "string"
          and item.description
          or "",

      category =
        type(item.category) == "string"
          and item.category
          or "",

      sourceFile =
        type(item.sourceFile) == "string"
          and item.sourceFile
          or "",

      sourceLine =
        tonumber(item.sourceLine) or 0,

      submap =
        type(item.submap) == "string"
          and item.submap
          or "",
    })
  end

  local warnings = {}

  for _, warning in ipairs(
    type(decoded.warnings) == "table"
      and decoded.warnings
      or {}
  ) do
    if type(warning) == "string" then
      table.insert(warnings, warning)
    end
  end

  return {
    schema = CACHE_SCHEMA,

    request = {
      parser = decoded.request.parser,
      root = decoded.request.root,
    },

    bindings = cachedBindings,
    warnings = warnings,
    sources = decoded.sources,
    globs = decoded.globs,
  }
end

local function cachePath()
  local directory, err =
    noctalia.pluginDataDir()

  if directory == nil then
    noctalia.log(
      "Could not resolve plugin data directory: "
        .. (err or "unknown error")
    )

    return nil
  end

  return directory
    .. "/"
    .. BINDINGS_CACHE_FILE
end

local function readBindingCache()
  local path = cachePath()

  if path == nil then
    return nil
  end

  local raw = noctalia.readFile(path)

  if raw == nil or raw == "" then
    return nil
  end

  local decoded =
    noctalia.json.decode(raw)

  return normalizedCache(decoded)
end

local function cachedBindingValue(binding)
  return {
    bindingType = binding.bindingType,

    modifiers = binding.modifiers,

    key = binding.key,

    action = binding.action,

    description = binding.description,

    category =
      binding.baseCategory
        or binding.category,

    sourceFile = binding.sourceFile,

    sourceLine = binding.sourceLine,

    submap = binding.submap,
  }
end

local function saveBindingCache(cache)
  local path = cachePath()

  if path == nil then
    return
  end

  local serializedBindings = {}

  for _, binding in ipairs(cache.bindings) do
    table.insert(
      serializedBindings,
      cachedBindingValue(binding)
    )
  end

  local encoded, encodeError =
    noctalia.json.encode(
      {
        schema = CACHE_SCHEMA,
        request = cache.request,
        bindings = serializedBindings,
        warnings = cache.warnings,
        sources = cache.sources,
        globs = cache.globs,
      },
      false
    )

  if encoded == nil then
    noctalia.log(
      "Could not encode hypr cheatsheet cache: "
        .. (encodeError or "unknown error")
    )

    return
  end

  local temporary = path .. ".tmp"

  local written, writeError =
    noctalia.writeFile(
      temporary,
      encoded
    )

  if not written then
    noctalia.log(
      "Could not write hypr cheatsheet cache: "
        .. (writeError or "unknown error")
    )

    return
  end

  local renamed, renameError =
    noctalia.renameFile(
      temporary,
      path
    )

  if not renamed then
    noctalia.removeFile(temporary)

    noctalia.log(
      "Could not commit hypr cheatsheet cache: "
        .. (renameError or "unknown error")
    )
  end
end

local function snapshot(
  status,
  request,
  cache,
  err,
  isRefreshing
)
  return {
    schema = CACHE_SCHEMA,

    status = status,

    parser =
      request ~= nil
        and request.parser
        or "",

    source =
      request ~= nil
        and request.root
        or "",

    request = request,

    bindings =
      cache ~= nil
        and cache.bindings
        or {},

    warnings =
      cache ~= nil
        and cache.warnings
        or {},

    error = err or "",

    refreshing =
      isRefreshing == true,
  }
end

local function publish(
  status,
  request,
  cache,
  err,
  isRefreshing
)
  noctalia.state.set(
    SNAPSHOT_KEY,
    snapshot(
      status,
      request,
      cache,
      err,
      isRefreshing
    )
  )
end

local function matchingLastGood(request)
  if requestsMatch(
    lastGood ~= nil
      and lastGood.request
      or nil,
    request
  ) then
    return lastGood
  end

  return nil
end

local function finishRefresh(
  generation,
  request,
  result,
  warnings,
  err,
  sourceSnapshot
)
  if generation ~= refreshGeneration then
    return
  end

  refreshing = false

  if err == nil then
    lastGood = {
      schema = CACHE_SCHEMA,

      request = request,

      bindings = result or {},

      warnings = warnings or {},

      sources =
        sourceSnapshot ~= nil
          and sourceSnapshot.sources
          or {},

      globs =
        sourceSnapshot ~= nil
          and sourceSnapshot.globs
          or {},
    }

    saveBindingCache(lastGood)

    publish(
      "ready",
      request,
      lastGood,
      "",
      false
    )
  else
    local previous =
      matchingLastGood(request)

    if previous ~= nil then
      publish(
        "ready",
        request,
        previous,
        err,
        false
      )
    else
      publish(
        "error",
        request,
        nil,
        err,
        false
      )
    end
  end

  if refreshQueued then
    refreshQueued = false
    refresh(request)
  end
end

local function configReadError(context)
  if context.rootRead then
    return nil
  end

  return tr("missing_config")
end

local function scheduleHyprStep(job, raw)
  hyprStepCounter += 1

  local value = {
    generation = job.generation,
    request = job.request,
    step = hyprStepCounter,
  }

  if raw ~= nil then
    value.raw = raw
  end

  noctalia.state.set(
    HYPR_STEP_KEY,
    value
  )
end

local function finishHyprJob(job)
  if job.generation ~= refreshGeneration
    or hyprJob ~= job
  then
    return
  end

  local warnings =
    job.warnings or {}

  local sourceSnapshot =
    job.sourceSnapshot

  local result =
    job.bindings or {}

  local err =
    job.error

  hyprJob = nil

  noctalia.state.set(
    HYPR_STEP_KEY,
    nil
  )

  finishRefresh(
    job.generation,
    job.request,
    result,
    warnings,
    err,
    sourceSnapshot
  )
end

local function hyprStep(value)
  local job = hyprJob

  if job == nil
    or type(value) ~= "table"
    or value.generation ~= refreshGeneration
    or value.generation ~= job.generation
    or value.step ~= hyprStepCounter
    or not requestsMatch(
      value.request,
      job.request
    )
  then
    return
  end

  if job.phase == "decode" then
    job.raw = value.raw or ""

    if job.result.exitCode ~= 0
      or job.result.timedOut
    then
      job.error =
        trim(job.result.stderr)

      if job.error == "" then
        job.error =
          tr("hyprctl_failed")
      end

      job.phase = "finish"

      scheduleHyprStep(job)

      return
    end

    local decoded, err =
      parseHyprJsonEntries(job.raw)

    if decoded == nil then
      job.error = err
      job.phase = "finish"

      scheduleHyprStep(job)

      return
    end

    job.entries = decoded
    job.raw = nil
    job.index = 1
    job.bindings = {}
    job.phase = "build"

    scheduleHyprStep(job)

    return
  end

  if job.phase == "build" then
    local limit =
      math.min(
        #job.entries,
        job.index
          + HYPR_BINDING_SLICE
          - 1
      )

    while job.index <= limit do
      local binding =
        hyprBindingFromEntry(
          job.entries[job.index]
        )

      if binding ~= nil then
        table.insert(
          job.bindings,
          binding
        )
      end

      job.index += 1
    end

    if job.index <= #job.entries then
      scheduleHyprStep(job)
      return
    end

    job.phase = "finish"

    scheduleHyprStep(job)

    return
  end

  if job.phase == "finish" then
    finishHyprJob(job)
  end
end

noctalia.state.watch(
  HYPR_STEP_KEY,
  hyprStep
)

local function refreshHypr(generation, request)
  if not noctalia.commandExists("hyprctl") then
    finishRefresh(
      generation,
      request,
      {},
      {},
      tr("hyprctl_missing"),
      nil
    )

    return
  end

  local accepted =
    noctalia.runAsync(
      "hyprctl binds -j",
      function(result)
        if generation ~= refreshGeneration then
          return
        end

        hyprJob = {
          generation = generation,
          request = request,
          result = result,
          phase = "decode",
        }

        scheduleHyprStep(
          hyprJob,
          result.stdout or ""
        )
      end,
      10000
    )

  if not accepted then
    finishRefresh(
      generation,
      request,
      {},
      {},
      tr("hyprctl_failed"),
      nil
    )
  end
end

local function performRefresh(
  generation,
  request
)
  if request == nil then
    finishRefresh(
      generation,
      {
        parser = "",
        root = "",
      },
      {},
      {},
      tr("unsupported"),
      nil
    )

    return
  end

  if request.parser == "lua" then
    refreshHypr(
      generation,
      request
    )

    return
  end

  if request.parser == "hyprlang" then
    local context =
      readConfig(
        request.root,
        parseHyprContent
      )

    finishRefresh(
      generation,
      request,
      context.bindings,
      context.warnings,
      configReadError(context),
      context
    )

    return
  end

  finishRefresh(
    generation,
    request,
    {},
    {},
    tr("unsupported"),
    nil
  )
end

local function refresh(request)
  if refreshing then
    refreshQueued = true
    return
  end

  request =
    request or currentRequest()

  refreshGeneration += 1

  local generation =
    refreshGeneration

  refreshing = true

  local previous =
    matchingLastGood(request)

  if previous == nil then
    publish(
      "loading",
      request,
      nil,
      "",
      true
    )
  end

  performRefresh(
    generation,
    request
  )
end

local function loadCachedSnapshot(request)
  local cached =
    readBindingCache()

  if requestsMatch(
    cached ~= nil
      and cached.request
      or nil,
    request
  ) then
    lastGood = cached

    publish(
      "ready",
      request,
      cached,
      "",
      true
    )
  else
    lastGood = nil

    publish(
      "loading",
      request,
      nil,
      "",
      true
    )
  end
end

local function bootstrap()
  local request =
    currentRequest()

  loadCachedSnapshot(request)

  refresh(request)
end

local function lifecycleState()
  local current =
    noctalia.state.get(
      SNAPSHOT_KEY
    )

  return {
    refreshing = refreshing,

    refreshQueued =
      refreshQueued,

    bindingCount =
      type(current) == "table"
        and type(current.bindings) == "table"
        and #current.bindings
        or 0,

    cacheLoaded =
      lastGood ~= nil,
  }
end

local function resetForTests()
  refreshGeneration += 1

  refreshing = false
  refreshQueued = false
  lastGood = nil

  bootstrap()
end

local function containsAll(values, required)
  local found = {}

  for _, value in ipairs(values) do
    found[value] = true
  end

  for _, value in ipairs(required or {}) do
    if not found[value] then
      return false, value
    end
  end

  return true, nil
end

local function selfTestBindings()
  local request =
    currentRequest()

  if request == nil then
    return {}
  end

  if request.parser == "hyprlang" then
    return walkConfig(
      request.root,
      parseHyprContent
    ).bindings
  end

  local result =
    noctalia.runCommand(
      "hyprctl binds -j"
    )

  if result == nil
    or result.exitCode ~= 0
  then
    return {}
  end

  return parseHyprJson(
    result.stdout or "[]"
  ) or {}
end

local function finishSelfTest(report)
  local encoded =
    noctalia.json.encode(
      report,
      true
    ) or "{}"

  local dataDir =
    noctalia.pluginDataDir()

  if dataDir ~= nil then
    noctalia.writeFile(
      dataDir .. "/selftest.json",
      encoded
    )
  end

  noctalia.log(
    "Hypr cheatsheet self-test: "
      .. encoded
  )

  if report.passed then
    noctalia.notify(
      tr("title"),
      "Parser self-test passed"
    )
  else
    noctalia.notifyError(
      tr("title"),
      "Parser self-test failed; see the Noctalia log"
    )
  end
end

local function runSelfTest()
  local bindings =
    selfTestBindings()

  local descriptions = {}
  local categories = {}

  for _, binding in ipairs(bindings) do
    table.insert(
      descriptions,
      binding.description
    )

    table.insert(
      categories,
      binding.category
    )
  end

  local report = {
    passed = true,
    bindingCount = #bindings,
    descriptions = descriptions,
    categories = categories,
  }

  finishSelfTest(report)
end

function onConfigChanged()
  local request =
    currentRequest()

  local current =
    noctalia.state.get(
      SNAPSHOT_KEY
    )

  if requestsMatch(
    type(current) == "table"
      and current.request
      or nil,
    request
  ) then
    return
  end

  refreshGeneration += 1
  refreshing = false
  refreshQueued = false

  loadCachedSnapshot(request)
  refresh(request)
end

function onIpc(event, _payload)
  if event == "refresh" then
    refresh()
  elseif event == "self-test" then
    runSelfTest()
  end
end

function onExit(_signal)
  refreshGeneration += 1
  refreshing = false
  refreshQueued = false
  hyprJob = nil
end

noctalia.state.watch(
  REFRESH_REQUEST_KEY,
  function(_request)
    refresh()
  end
)

noctalia.state.watch(
  SELF_TEST_REQUEST_KEY,
  function(_request)
    runSelfTest()
  end
)

bootstrap()

return {
  parseHyprContent = parseHyprContent,
  parseHyprJson = parseHyprJson,
  walkConfig = walkConfig,
  configReadError = configReadError,
  currentRequest = currentRequest,
  requestsMatch = requestsMatch,
  normalizedCache = normalizedCache,
  refresh = refresh,
  bootstrap = bootstrap,
  resetForTests = resetForTests,
  lifecycleState = lifecycleState,
  onConfigChanged = onConfigChanged,
  onIpc = onIpc,
  onExit = onExit,
  runSelfTest = runSelfTest,
  snapshotKey = SNAPSHOT_KEY,
  refreshRequestKey = REFRESH_REQUEST_KEY,
}
