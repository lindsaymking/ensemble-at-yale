# @cjsx React.DOM
React           = require 'react'
Draggable       = require '../../../../lib/draggable'
DoneButton      = require './done-button'

TextTool = React.createClass
  displayName: 'TextTool'

  handleInitStart: (e) ->
    # console.log 'handleInitStart() '
    @setState preventDrag: false
    if e.target.nodeName is "INPUT" or e.target.nodeName is "TEXTAREA"
      @setState preventDrag: true
      
    @setState
      xClick: e.pageX - $('.transcribe-tool').offset().left
      yClick: e.pageY - $('.transcribe-tool').offset().top

  handleInitDrag: (e, delta) ->

    return if @state.preventDrag # not too happy about this one

    dx = e.pageX - @state.xClick - window.scrollX
    dy = e.pageY - @state.yClick # + window.scrollY

    @setState
      dx: dx
      dy: dy #, =>
      dragged: true

  getInitialState: ->
    viewerSize: @props.viewerSize
    annotation:
      value: ''

  getDefaultProps: ->
    annotation: {}
    task: null
    subject: null
    standalone: true
    annotation_key: 'value'
    focus: true
   
  componentWillReceiveProps: ->
    @setState
      annotation: @props.annotation

    # console.log "focus(receive props)? ", @props.focus
    @refs.input0.getDOMNode().focus() if @props.focus

  componentWillUnmount: ->
    if @props.task.tool_options.suggest == 'common'
      el = $(@refs.input0.getDOMNode())
      el.autocomplete 'destroy'

  componentDidMount: ->
    @updatePosition()
    @refs.input0.getDOMNode().focus() if @props.focus

    if @props.task.tool_options.suggest == 'common'
      el = $(@refs.input0.getDOMNode())
      el.autocomplete
        source: (request, response) =>
          $.ajax
            url: "/classifications/terms/#{@props.workflow.id}/#{@props.key}"
            dataType: "json"
            data:
              q: request.term
            success: ( data ) =>
              response( data )
        minLength: 3
      
  # Expects size hash with:
  #   w: [viewer width]
  #   h: [viewer height]
  #   scale: 
  #     horizontal: [horiz scaling of image to fit within above vals]
  #     vertical:   [vert scaling of image..]
  onViewerResize: (size) ->
    @setState
      viewerSize: size
    @updatePosition()

  updatePosition: ->
    if @state.viewerSize? && ! @state.dragged
      @setState
        dx: @props.subject.data.x * @state.viewerSize.scale.horizontal
        dy: (@props.subject.data.y + @props.subject.data.height) * @state.viewerSize.scale.vertical
      # console.log "TextTool#updatePosition setting state: ", @state

  commitAnnotation: ->
    @props.onComplete @state.annotation

  handleChange: (e) ->
    @state.annotation[@props.annotation_key] = e.target.value
    @forceUpdate()

  handleKeyPress: (e) ->

    if [13].indexOf(e.keyCode) >= 0 # ENTER:
      @commitAnnotation()
      e.preventDefault()

    # else if [27].indexOf(e.keyCode) >= 0 # ESC: 
      # cancel ann? 



  render: ->
    # return null unless @props.viewerSize? && @props.subject?

    # If user has set a custom position, position based on that:
    style =
      left: @state.dx
      top: @state.dy
    # console.log "TextTool#render pos", @state

    val = @state.annotation[@props.annotation_key] ? ''
    # console.log "TextTool#render val:", val, @state.annotation?.value

    label = @props.task.instruction
    if ! @props.standalone
      label = @props.label ? ''

    tool_content =
      <div className="input-field active">
        <label>{label}</label>
        <input ref="input0" type="text" data-task_key={@props.task.key} onKeyDown={@handleKeyPress} onChange={@handleChange} value={val} />
      </div>

    if @props.standalone
      tool_content =
        <Draggable
          onStart = {@handleInitStart}
          onDrag  = {@handleInitDrag}
          onEnd   = {@handleInitRelease}
          ref     = "inputWrapper0">

          <div className="transcribe-tool" style={style}>
            <div className="left">
              { tool_content }
            </div>
            <div className="right">
              <DoneButton onClick={@commitAnnotation} />
            </div>
          </div>
        </Draggable>

    tool_content

module.exports = TextTool