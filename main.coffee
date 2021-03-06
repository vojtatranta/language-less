# Deps

{css, utils} = require 'octopus-helpers'
{_} = utils


# Private fns

_declaration = ($$, lessMixinSyntax, interpolatedSyntax, property, value, modifier) ->
  return if not value? or value == ''

  value = modifier(value) if modifier

  value = "~\"#{value}\"" if interpolatedSyntax and lessMixinSyntax

  if lessMixinSyntax
    $$ ".#{property}(#{value});"
  else
    $$ "#{property}: #{value};"


renderColor = (color, colorVariable) ->
  if color.a < 1
    "fade(#{colorVariable}, #{100 - color.a * 100})"
  else
    renderVariable(colorVariable)


_comment = ($, showComments, text) ->
  return unless showComments
  $ "// #{text}"


defineVariable = (name, value, options) ->
  "@#{name}: #{value};"


renderVariable = (name) -> "@#{name}"


_convertColor = _.partial(css.convertColor, renderColor)


_startSelector = ($, selector, selectorOptions, text) ->
  return unless selector
  $ '%s%s', utils.prettySelectors(text, selectorOptions), ' {'


_endSelector = ($, selector) ->
  return unless selector
  $ '}'


setNumberValue = (number) ->
  converted = parseInt(number, 10)
  if not number.match(/^\d+(\.\d+)?$/)
    return 'Please enter numeric value'
  else
    return converted


class Less

  render: ($) ->
    $$ = $.indents
    declaration = _.partial(_declaration, $$, false, false)
    mixin = _.partial(_declaration, $$, @options.enableLessHat, @options.useInterpolationSyntax)
    comment = _.partial(_comment, $, @options)
    boxModelDimension = _.partial(css.boxModelDimension, @options.boxSizing, if @borders then @borders[0].width else null)

    rootValue = switch @options.unit
      when 'px' then 0
      when 'em' then @options.emValue
      when 'rem' then @options.remValue
    unit = _.partial(css.unit, @options.unit, rootValue)

    lhRoot = switch @options.lineHeightUnit
      when 'px' then 0
      when 'em' then @options.emValue
      when 'rem' then @options.remValue
    lineHeightUnit = _.partial(css.lineHeightUnit, @options.lineHeightUnit, unit, lhRoot)
    isUnitlessLh = @options.lineHeightUnit.toLowerCase().indexOf('unitless') isnt -1

    convertColor = _.partial(_convertColor, @options)
    fontStyles = _.partial(css.fontStyles, declaration, convertColor, unit, lineHeightUnit, isUnitlessLh, @options.quoteType)

    selectorOptions =
      separator: @options.selectorTextStyle
      selector: @options.selectorType
      maxWords: 3
      fallbackSelectorPrefix: 'layer'
    startSelector = _.partial(_startSelector, $, @options.selector, selectorOptions)
    endSelector = _.partial(_endSelector, $, @options.selector)

    if @type == 'textLayer'
      for textStyle in css.prepareTextStyles(@options.inheritFontStyles, @baseTextStyle, @textStyles)

        if @options.showComments
          comment(css.textSnippet(@text, textStyle))

        if @options.selector
          if textStyle.ranges
            selectorText = utils.textFromRange(@text, textStyle.ranges[0])
          else
            selectorText = @name

          startSelector(selectorText)

        if not @options.inheritFontStyles or textStyle.base
          if @options.showAbsolutePositions
            declaration('position', 'absolute')
            declaration('left', @bounds.left, unit)
            declaration('top', @bounds.top, unit)

          if @bounds
            if @options.enableLessHat
              if @bounds.width == @bounds.height
                mixin('size', @bounds.width, unit)
              else
                mixin('size', "#{unit(@bounds.width)}, #{unit(@bounds.height)}")
            else
              declaration('width', @bounds.width, unit)
              declaration('height', @bounds.height, unit)

          mixin('opacity', @opacity)

          if @shadows
            declaration('text-shadow', css.convertTextShadows(convertColor, unit, @shadows))

        fontStyles(textStyle)

        endSelector()
        $.newline()
    else
      if @options.showComments
        comment("Style for \"#{utils.trim(@name)}\"")

      startSelector(@name)

      if @options.showAbsolutePositions
        declaration('position', 'absolute')
        declaration('left', @bounds.left, unit)
        declaration('top', @bounds.top, unit)

      if @bounds
        width = boxModelDimension(@bounds.width)
        height = boxModelDimension(@bounds.height)

        if @options.enableLessHat
          if width is height
            mixin('size', width, unit)
          else
            mixin('size', "#{unit(width)}, #{unit(height)}")
        else
          declaration('width', width, unit)
          declaration('height', height, unit)

      mixin('opacity', @opacity)

      if @background
        declaration('background-color', @background.color, convertColor)

        if @background.gradient
          mixin('background-image', css.convertGradients(convertColor, {gradient: @background.gradient, @bounds}))

      if @borders
        border = @borders[0]
        declaration('border', "#{unit(border.width)} #{border.style} #{convertColor(border.color)}")

      mixin('border-radius', @radius, _.partial(css.radius, unit))

      if @shadows
        mixin('box-shadow', css.convertShadows(convertColor, unit, @shadows))

      endSelector()

metadata = require './package.json'

module.exports = {defineVariable, renderVariable, setNumberValue, renderClass: Less, metadata}
