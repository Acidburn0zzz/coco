# A simple **OptionParser** class to parse option flags from the command-line.
# Use it like so:
#
#     parser  = new OptionParser switches, helpBanner
#     options = parser.parse process.argv
#
# The first non-option is considered to be the start of the file (and file
# option) list, and all subsequent arguments are left unparsed.
exports.OptionParser = class

  # Initialize with a list of valid options, in the form:
  #
  #     [short-flag, long-flag, description]
  #
  # Along with an an optional banner for the usage help.
  (rules, @banner) -> @rules = buildRules rules

  # Parse the list of arguments, populating an `options` object with all of the
  # specified options, and returning it. `options.arguments` will be an array
  # containing the remaining non-option arguments. This is a simpler API than
  # many option parsers that allow you to attach callback actions for every
  # flag. Instead, you're responsible for interpreting the options object.
  parse: (args) ->
    options = arguments: []
    for arg, i of args = normalizeArguments args
      isOption    = !!(LONG_FLAG.test(arg) or SHORT_FLAG.test(arg))
      matchedRule = false
      for rule of @rules
        if arg of [rule.shortFlag, rule.longFlag]
          value = if rule.hasArgument then args[i += 1] else true
          options[rule.name] = if rule.isList
          then (options[rule.name] or []).concat value
          else value
          matchedRule = true
          break
      if isOption and not matchedRule
        console.error "unrecognized option: #{arg}"
        process.exit 1
      unless isOption
        options.arguments = args.slice i
        break
    options

  # Return the help text for this **OptionParser**, listing and describing all
  # of the valid options, for `--help` and such.
  help: ->
    lines = ['Available options:']
    lines.unshift @banner + '\n' if @banner
    width = Math.max @rules.map(-> it.longFlag.length)...
    pad   = Array(width >> 1).join '  '
    for rule of @rules
      sf = if rule.shortFlag then rule.shortFlag + ','  else '   '
      lf = (rule.longFlag + pad).slice 0, width
      lines.push "  #{sf} #{lf}  #{rule.description}"
    "\n#{ lines.join '\n' }\n"

# Helpers
# -------

# Regex matchers for option flags.
LONG_FLAG  = /^--\w[\w\-]+/
SHORT_FLAG = /^-\w/
MULTI_FLAG = /^-(\w{2,})/
OPTIONAL   = /\[(\w+(\*?))\]/

# Build and return the list of option rules. If the optional *short-flag* is
# unspecified, leave it out by padding with `null`.
buildRules = (rules) ->
  for tuple of rules
    tuple.unshift null if tuple.length < 3
    buildRule tuple...

# Build a rule from a `-o` short flag, a `--output [DIR]` long flag, and the
# description of what the option does.
buildRule = (shortFlag, longFlag, description) ->
  match      = longFlag.match OPTIONAL
  [longFlag] = longFlag.match LONG_FLAG
  {
    shortFlag, longFlag, description
    name        : longFlag.slice 2
    hasArgument : !!match?[1]
    isList      : !!match?[2]
  }

# Normalize arguments by expanding merged flags into multiple flags. This allows
# you to have `-wl` be the same as `--watch --lint`.
normalizeArguments = (args) ->
  Array::concat.apply [], args.map ->
    return it unless match = MULTI_FLAG.exec it
    '-' + l for l of match[1].split ''
