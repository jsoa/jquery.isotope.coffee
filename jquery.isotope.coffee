
#  Isotope written in coffesript
#  by Jose Soares
#
#  This is simply a rewrite in coffeescript, mostly for me to
#  learn coffeescript.
#
#  All original code can be found at
#  https://github.com/desandro/isotope.
#
#  This does not add any new functionality. Most of the original
#  code comments are in place.
#
#  Original license apply
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Isotope v1.5.14
#  An exquisite jQuery plugin for magical layouts
#  http://isotope.metafizzy.co
#
#  Commercial use requires one-time license fee
#  http://metafizzy.co/#licenses
#
#  Copyright 2012 David DeSandro / Metafizzy

(( window, $ ) ->

  'use strict'

  # get global vars
  document = window.document
  Modernizr = window.Modernizr

  # helper function
  capitalize =  ( str ) ->
    str.charAt(0).toUpperCase() + str.slice(1)

  prefixes = 'Moz Webkit O Ms'.split ' '

  getStyleProperty = ( propName ) ->
    style = document.documentElement.style

    # test standard property first
    if typeof style[ propName ] is 'string'
      return propName

    # capitalize
    propName = capitalize propName

    # test vendor specific properties
    for prefix in prefixes
      prefixed = prefix + propName
      if typeof style[ prefixed ] is 'string'
        return prefixed

  transformProp = getStyleProperty 'transform'
  transitionProp = getStyleProperty 'transitionProperty'

  #  ======================= miniModernizr =============================

  tests = {
    csstransforms: ->
      not not transformProp

    csstransforms3d: ->
      test = not not getStyleProperty 'perspective'
      # double check for Chrome's false positive
      if test
        vendorCSSPrefixes = ' -o- -moz- -ms- -webkit- -khtml- '.split ' '
        mediaQuery = '@media (' + vendorCSSPrefixes.join('transform-3d),(') + 'modernizr)'
        $style = $('<style>' + mediaQuery + '{#modernizr{height:3px}}' + '</style>')
          .appendTo('head')
        $div = $('<div id="modernizr" />').appendTo 'html'

        test = $div.height() is 3

        $div.remove()
        $style.remove()
      return test

    csstransitions: ->
      not not transitionProp
  }

  if Modernizr
    # if there's a previous Medernizr, check if there are necessary tests
    for testName of tests
      unless Modernizr.hasOwnProperty( testName )
        # if test hasn't been run, addTest to run it
        Modernizr.addTest testName, tests[ testName ]
  else
    # or create new mini Modernizr that just has the 3 tests
    Modernizr = window.Modernizr = {
      _version: '1.6ish: miniModernizr for Isotope'
    }

    classes = ' '

    # Run through tests
    for testName of tests
      result = tests[ testName ]()
      Modernizr[ testName ] = result
      classes += ' ' + ( if result then '' else 'no-' ) + testName

    $('html').addClass classes

  # ======================== isoTransform ==============================

  if Modernizr.csstransforms
    # 3D transform functions
    transform3dFns = {
      translate : ( position ) ->
        return 'translate3d(' + position[0] + 'px, ' + position[1] + 'px, 0) '

      scale : ( scale ) ->
        return 'scale3d(' + scale + ', ' + scale + ', 1) '
    }
    # 2D transform functions
    transform2dFns = {
      translate : ( position ) ->
        return 'translate(' + position[0] + 'px, ' + position[1] + 'px) '

      scale : ( scale ) ->
        return 'scale(' + scale + ') '
    }

    transformFnNotations = if Modernizr.csstransforms3d then transform3dFns else transform2sFns

    setIsoTransform = ( elem, name, value ) ->
      data = $.data( elem, 'isoTransform' ) or {}
      newData = {}
      transformObj = {}

      # i.e. newData.scale = 0.5
      newData[ name ] = value
      # extend new value over current data
      $.extend data, newData

      for fnName of data
        transformValue = data[ fnName ]
        transformObj[ fnName ] = transformFnNotations[ fnName ]( transformValue )

      # get proper order
      # ideally, we could loop through this give an array, but since we only
      # have a couple transforms we're keeping track of, we'll do it like so
      translateFn = transformObj.translate or ''
      scaleFn = transformObj.scale or ''
      # sorting so translate always comes first
      valueFns = translateFn + scaleFn

      # set data back in elem
      $.data elem, 'isoTransform', data

      # set name to vendor specific property
      elem.style[ transformProp ] = valueFns

    # ==================== scale ===================

    $.cssNumber.scale = true

    $.cssHooks.scale = {
      set: ( elem, value ) ->
        setIsoTransform elem, 'scale', value

      get: ( elem, computed ) ->
        transform = $.data elem, 'isoTransform'
        return transform and if transform.scale then transform.scale else 1
      }

    $.fx.step.scale = ( fx ) ->
      $.cssHooks.scale.set fx.elem, fx.now + fx.unit

    # ==================== translate ===================

    $.cssNumber.translate = true

    $.cssHooks.translate = {
      set: ( elem, value ) ->
        setIsoTransform elem, 'translate', value

      get: ( elem, computed ) ->
        transform = $.data elem, 'isoTransform'
        return transform and if transform.translate then transform.translate else [ 0, 0 ]
    }

  # ================== get transition-end event ========================

  if Modernizr.csstransitions
    transitionEndEvent = {
      WebkitTransitionProperty: 'webkitTransitionEnd',
      MozTransitionProperty: 'transitionend',
      OTransitionProperty: 'oTransitionEnd',
      transitionProperty: 'transitionEnd',
    }[ transitionProp ]

    transitionDurProp = getStyleProperty 'transitionDuration'

  # ========================= smartresize ===============================

  $event = $.event

  $event.special.smartresize = {
    setup: ->
      $(@).bind "resize", $event.special.smartresize.handler

    teardown: ->
      $(@).unbind "resize", $event.special.smartresize.handler

    handler: ( event, execAsap ) ->
      context = @
      args = arguments

      event.type = "smartresize"

      if resizeTimeout then clearTimeout resizeTimeout

      resizeTimeout = setTimeout( ->
        jQuery.event.handle.apply context, args
      , execAsap is if "execAsap" then 0 else 100)
  }

  $.fn.smartresize = ( fn ) ->
    if fn then @bind( "smartresize", fn ) else @trigger( "smartresize", ["execAsap"] )

  # =========================== Isotope =================================

  $.Isotope = ( options, element, callback ) ->
    @element = $ element

    @_create options
    @_init callback

  isoContainerStyles = [ 'width', 'height' ]

  $window = $ window

  $.Isotope.settings = {
    resizable : true
    layoutMode : 'masonry'
    containerClass : 'isotope'
    itemClass : 'isotope-item'
    hiddenClass : 'isotope-hidden'
    hiddenStyle : { opacity: 0, scale: 0.001 }
    visibleStyle : { opacity: 1, scale: 1 }
    containerStyle : { position : 'relative', overflow : 'hidden' }
    animationEngine : 'best-available'
    animationOptions : { queue : false, duration : 800 }
    sortBy : 'original-order'
    sortAscending : true
    resizesContainer : true
    transformsEnabled : not $.browser.opera
    itemPositionDataEnabled : false
  }

  $.Isotope:: = {

    # sets up widget
    _create : ( options ) ->
      @options = $.extend {}, $.Isotope.settings, options

      @styleQueue = []
      @elemCount = 0

      # get orginal styles in case we re-apply them in .destroy()
      elemStyle = @element[0].style
      @originalStyle = {}
      # keep track of container styles
      containerStyles = isoContainerStyles.slice 0

      for prop in @options.containerStyle
        containerStyles.push prop

      for prop in containerStyles
        @originalStyle[ prop ] = elemStyle[ prop ] or ''

      # apply container style from options
      @element.css @options.containerStyle

      @_updateAnimationEngine()
      @_updateUsingTransforms()

      # sorting
      originalOrderSorter = {
        'original-order' : ( $elem, inst ) ->
          inst.elemCount++
          return inst.elemCount

        random : ->
          return Math.random()
      }

      @options.getSortData = $.extend @options.getSortData, originalOrderSorter
      # need to get atoms
      @reloadItems()

      # get top left position of where the bricks should be
      @offset = {
        left: parseInt @element.css('padding-left'), 10
        top: parseInt @element.css('padding-top'), 10
      }

      # add isotope class first time around
      instance = @
      setTimeout( ->
        instance.element.addClass( instance.options.containerClass )
      , 0)

      # bind resize method
      if @options.resizable
        $window.bind 'smartresize.isotope', ->
          instance.resize()

      # dismiss all click events from hidden events
      @element.delegate '.' + @options.hiddenClass, 'click', ->
        return false

    _getAtoms : ( $elems ) ->
      selector = @options.itemSelector
      # filter & find
      $atoms = if selector then $elems.filter( selector ).add( $elems.find( selector ) ) else $elems
      # base style for atoms
      atomStyle = { position : 'absolute' }
      if @usingTransforms
        atomStyle.left = 0
        atomStyle.top = 0

      $atoms.css( atomStyle ).addClass( @options.itemClass )

      @updateSortData $atoms, true

      return $atoms

    # _init fires when your instance is first created
    # (from the constructor above), and then you
    # attempt to initialize the widget again (by the bridge)
    # after it has already need initialized
    _init : ( callback ) ->

      @$filteredAtoms = @_filter @$allAtoms
      @_sort()
      @reLayout callback

    option : ( opts ) ->
      # change options AFTER initialization:
      # signature: $('#foo').bar({ cool:false});
      if $.isPlainObject( opts )
        @options = $.extend true, @options, opts

        # trigger _updateOptionName if it exists
        for optionName of opts
          updateOptionFn = '_update' + capitalize( optionName )
          @[ updateOptionFn ]() if @[ updateOptionFn ]

        return

    # ====================== updaters ======================
    # kind of like setters

    _updateAnimationEngine : ->
      animationEngine = @options.animationEngine.toLowerCase().replace( /[ _\-]/g, '')

      # set applyStyleFnName
      switch animationEngine
        when 'css', 'none'
          isUsingJQueryAnimation = false
        when 'jquery'
          isUsingJQueryAnimation = true
        else
          isUsingJQueryAnimation = not Modernizr.csstransitions

      @isUsingJQueryAnimation = isUsingJQueryAnimation
      @_updateUsingTransforms()

    _updateTransformsEnabled : ->
      @_updateUsingTransforms()

    _updateUsingTransforms : ->
      usingTransforms = @usingTransforms = @options.transformsEnabled and
        Modernizr.csstransforms and Modernizr.csstransitions and not @isUsingJQueryAnimation

      # prevent scales when transforms are disabled
      unless usingTransforms
        delete @options.hiddenStyle.scale
        delete @options.visibleStyle.scale

      @getPositionStyles = if usingTransforms then @_translate else @_positionAbs

    # ======================= Filtering =======================

    _filter : ( $atoms ) ->
      filter = if @options.filter is '' then '*' else @options.filter

      unless filter
        return $atoms

      hiddenClass = @options.hiddenClass
      hiddenSelector = '.' + hiddenClass
      $hiddenAtoms = $atoms.filter hiddenSelector
      $atomsToShow = $hiddenAtoms

      if filter isnt '*'
        $atomsToShow = $hiddenAtoms.filter filter
        $atomsToHide = $atoms.not( hiddenSelector ).not( filter ).addClass( hiddenClass )
        @styleQueue.push { $el: $atomsToHide, style: @options.hiddenStyle }

      @styleQueue.push { $el: $atomsToShow, style: @options.visibleStyle }
      $atomsToShow.removeClass hiddenClass

      return $atoms.filter filter

    # ====================== Sorting ======================

    updateSortData : ( $atoms, isIncrementingElemCount ) ->
      instance = @
      getSortData = @options.getSortData

      $atoms.each ->
        $this = $ this
        sortData = {}
        # get value for sort data based on fn( $elem ) passed in
        for key of getSortData
          # keep original order original
          if ( not isIncrementingElemCount ) and key is 'original-order'
            sortData[ key ] = $.data( @, 'isotope-sort-data' )[ key ]
          else
            sortData[ key ] = getSortData[ key ] $this, instance
        # apply sort data to element
        $.data @, 'isotope-sort-data', sortData

    # used on all the filtered atoms
    _sort : ->
      sortBy = @options.sortBy
      getSorter = @_getSorter
      sortDir = if @options.sortAscending then 1 else -1
      sortFn = ( alpha, beta ) ->
        a = getSorter alpha, sortBy
        b = getSorter beta, sortBy
        # fall back to original order of data matches
        if a is b and sortBy isnt 'original-order'
          a = getSorter alpha, 'original-order'
          b = getSorter beta, 'original-order'
        return ( if ( a > b ) then 1 else if ( a < b ) then -1 else 0 ) * sortDir

      @$filteredAtoms.sort sortFn

    _getSorter : ( elem, sortBy ) ->
      return $.data( elem, 'isotope-sort-data' )[ sortBy ]

    # ======================= Layout Helpers ======================

    _translate : ( x, y ) ->
      return { translate : [ x, y ] }

    _positionAbs : ( x, y ) ->
      return { left: x, top: y }

    _pushPosition : ( $elem, x, y ) ->
      x = Math.round x + @offset.left
      y = Math.round y + @offset.top
      position = @getPositionStyles x, y
      @styleQueue.push { $el: $elem, style: position }
      if @options.itemPositionDataEnabled
        $elem.data 'isotope-item-position', { x: x, y: y }

    # ====================== General Layout ======================

    # used on collection of atoms (should be filtered, and sorted before )
    # accepts atoms-to-be-laid-out to start with
    layout : ( $elems, callback ) ->
      layoutMode = @options.layoutMode

      # layout logic
      @[ '_' + layoutMode + 'Layout' ] $elems

      # set the size of the container
      if @options.resizesContainer
        containerStyle = @[ '_' + layoutMode + 'GetContainerSize' ]()
        @styleQueue.push { $el: @element, style: containerStyle }

      @_processStyleQueue $elems, callback

      @isLaidOut = true

    _processStyleQueue : ( $elems, callback ) ->
      # are we animating the layout arragement?
      # use plugin-ish syntax for css or animate
      styleFn = if not @isLaidOut then 'css' else
        ( if @isUsingJQueryAnimation then 'animate' else 'css' )

      animOpts = @options.animationOptions
      onLayout = @options.onLayout
      objStyleFn = null

      # default styleQueue processor, may be overwritten down below
      processor = ( i, obj ) ->
        obj.$el[ styleFn ] obj.style, animOpts

      if @_isInserting and @isUsingJQueryAnimation
        # if using styleQueue to insert items
        processor = ( i, obj ) ->
          # only animate if it not being inserted
          objStyleFn = if obj.$el.hasClass( 'no-transition' ) then 'css' else styleFn
          obj.$el[ objStyleFn ] obj.style, animOpts

      else if callback or onLayout or animOpts.complete
        # has callback
        isCallbackTriggered = false
        # array of possible callbacks to trigger
        callbacks = [ callback, onLayout, animOpts.complete ]
        instance = @
        triggerCallbackNow = true
        # trigger callback only once
        callbackFn = ->
          if isCallbackTriggered
            return

          for hollaback in callbacks
            if typeof hollaback is 'function'
              hollaback.call instance.element, $elems
          isCallbackTriggered = true

        if @isUsingJQueryAnimation and styleFn is 'animate'
          # add callback to animation options
          animOpts.complete = callbackFn
          triggerCallbackNow = false
        else if Modernizr.csstransitions
          # detect if first item has trasition
          a = 0
          testElem = @styleQueue[0].$el
          # get first non-empty jQ object
          while not testElem.length
            styleObj = @styleQueue[ a++ ]
            # HACK: sometimes styleQueue[i] is undefined
            if not styleObj
              return
            testElem = styleObj.$el
          # get traisitions duration of the first element in that object
          # yeah, this is inexact
          duration = parseFloat( getComputedStyle( testElem[0] )[ transitionDurProp ] )
          if duration > 0
            processor = ( i, obj ) ->
              obj.$el[ styleFn ]( obj.style, animOpts )
              # trigger callback at transition end
              .one( transitionEndEvent, callbackFn )
            triggerCallbackNow = false

      # process styleQueue
      $.each @styleQueue, processor

      if triggerCallbackNow then callbackFn()

      # clear out queue for next time
      @styleQueue = []

    resize : ->
      @reLayout() if @[ '_' + @options.layoutMode + 'ResizeChanged' ]()

    reLayout : ( callback ) ->
      @[ '_' + @options.layoutMode + 'Reset' ]()
      @layout @$filteredAtoms, callback

    # ====================== Convenience methods ======================

    # ====================== Adding items ======================

    # adds a jQuery object of items to a isotope container
    addItems : ( $content, callback ) ->
      $newAtoms = @_getAtoms $content
      # add new atoms to atoms pools
      @$allAtoms = @$allAtoms.add $newAtoms

      if callback then callback $newAtoms

    # convienence method for adding elements properly to any layout
    # positions items, hides them, then animates them back in <--- very sezzy
    insert : ( $content, callback ) ->
      # position items
      @element.append $content

      instance = @
      @addItems $content, ( $newAtoms ) ->
        $newFilteredAtoms = instance._filter $newAtoms
        instance._addHideAppended $newFilteredAtoms
        instance._sort()
        instance.reLayout()
        instance._revealAppended $newFilteredAtoms, callback

    # convienence method for working with Infinite Scroll
    appended : ( $content, callback ) ->
      instance = @
      @addItems $content, ( $newAtoms ) ->
        instance._addHideAppended $newAtoms
        instance.layout $newAtoms
        instance._revealAppended $newAtoms, callback

    # adds new atoms, then hides them before positioning
    _addHideAppended : ( $newAtoms ) ->
      @$filteredAtoms = @$filteredAtoms.add $newAtoms
      $newAtoms.addClass 'no-trasition'

      @_isInserting = true

      # apply hidden styles
      @styleQueue.push { $el: $newAtoms, style: @options.hiddenStyle }

    # sets visible style on new atoms
    _revealAppended : ( $newAtoms, callback ) ->
      instance = @
      # apply visible style after a sec
      setTimeout( ->
        # enable animation
        $newAtoms.removeClass 'no-transition'
        # reveal newly inserted filtered elements
        instance.styleQueue.push { $el: $newAtoms, style: instance.options.visibleStyle }
        instance._isInserting = false
        instance._processStyleQueue $newAtoms, callback
      , 10)

    # gather all atoms
    reloadItems : ->
      @$allAtoms = @_getAtoms( @element.children() )

    # removes elements from Isotope widget
    remove : ( $content, callback ) ->
      # remove elements from Isotope instance in callback
      instance = @
      removeContent = ->
        instance.$allAtoms = instance.$allAtoms.not $content
        $content.remove()

      if $content.filter( ':not(.' + @options.hiddenClass + ')' ).length
        # if any non-hidden content needs to be removed
        @styleQueue.push { $el: $content, style: @options.hiddenStyle }
        @$filteredAtoms = @$filteredAtoms.not $content
        @_sort()
        @reLayout removeContent, callback
      else
        # remove it now
        removeContent()
        callback.call @element if callback

    shuffle : ( callback ) ->
      @updateSortData @$allAtoms
      @options.sortBy = 'random'
      @_sort()
      @reLayout callback

    # destroys widget, returns elements and container back (close) to original style
    destroy : ->
      usingTransforms = @usingTransforms
      options = @options

      @$allAtoms
        .removeClass( options.hiddenClass + ' ' + options.itemClass )
        .each ->
          style = @style
          style.position = ''
          style.top = ''
          style.left = ''
          style.opacity = ''
          if usingTransforms
            style[ transformProp ] = ''

      # re-apply saved container styles
      elemStyle = @element[0].style
      for prop of @originalStyle
        elemStyle[ prop ] = @originalStyle[ prop ]

      @element
        .unbind( '.isotope' )
        .undelegate( '.' + options.hiddenClass, 'click')
        .removeClass( options.containerClass )
        .removeData( 'isotope' )

      $window.unbind '.isotope'

    # ====================== LAYOUTS ======================

    # calculates number of rows or columns
    # requires columnWidth or rowHeight to be set on namespaced object
    # i.e. this.masonry.columnWidth = 200
    _getSegments : ( isRows ) ->
      namespace = @options.layoutMode
      measure = if isRows then 'rowHeight' else 'columnWidth'
      size = if isRows then 'height' else 'width'
      segmentsName = if isRows then 'rows' else 'cols'
      containerSize = @element[ size ]()

      # i.e. options.masonry && options.masonry.columnWidth
      segmentSize = @options[ namespace ] and @options[ namespace ][ measure ] or
      # or use the size of that first item, i.e. outerWidth; if there's
      # no items, use size of container
      @$filteredAtoms[ 'outer' + capitalize( size )]( true ) or containerSize

      segments = Math.floor containerSize / segmentSize
      segments = Math.max segments, 1

      # i.e. this.masonry.cols = ....
      @[ namespace ][ segmentsName ] = segments
      # i.e. this.masonry.columnWidth = ...
      @[ namespace ][ measure ] = segmentSize

    _checkIfSegmentsChanged : ( isRows ) ->
      namespace = @options.layoutMode
      segmentsName = if isRows then 'rows' else 'cols'
      prevSegments = @[ namespace ][ segmentsName ]
      # update cols/rows
      @_getSegments isRows
      # return if updated cols/rows is not equal to previous
      return @[ namespace ][ segmentsName ] isnt prevSegments

    # ====================== Masonry ======================

    _masonryReset : ->
      # layout-specific props
      @masonry = {}
      # FIXME shouldn't have to call this again
      @_getSegments()
      i = @masonry.cols
      @masonry.colYs = []
      while (i--)
        @masonry.colYs.push 0
      return

    _masonryLayout : ( $elems ) ->
      instance = @
      props = instance.masonry
      $elems.each ->
        $this = $ @
        # how many columns does this brick span
        colSpan = Math.ceil $this.outerWidth( true ) / props.columnWidth
        colSpan = Math.min colSpan, props.cols
        if colSpan is 1
          # if brick spans only one column, just like singleMode
          instance._masonryPlaceBrick $this, props.colYs
        else
          # brick spans more then one column
          # how many different places could this brick fit horizontally
          groupCount = props.cols + 1 - colSpan
          groupY = []

          # for each group potential horiontal position
          for i in [0...groupCount]
            # make an array of colY values for that one group
            groupColY = props.colYs.slice i, i+colSpan
            # and get the max value of the array
            groupY[i] = Math.max.apply Math, groupColY

          instance._masonryPlaceBrick $this, groupY

    # worker method that places blick in the columnSet
    # with the the minY
    _masonryPlaceBrick : ( $brick, setY ) ->
      # get the minimum Y value from the columns
      minimumY = Math.min.apply Math, setY
      shortCol = 0
      setYLen = setY.length

      # Find index of short column, the first from the left
      for set, i in setY
        if set is minimumY
          shortCol = i
          break

      # position the brick
      x = @masonry.columnWidth * shortCol
      y = minimumY
      @_pushPosition $brick, x, y

      # apply setHeight to necessary columns
      setHeight = minimumY + $brick.outerHeight true
      setSpan = @masonry.cols + 1 - setYLen
      for i in [0...setSpan]
        @masonry.colYs[ shortCol + i ] = setHeight
      return

    _masonryGetContainerSize : ->
      containerHeight = Math.max.apply Math, @masonry.colYs
      return { height: containerHeight }

    _masonryResizeChanged : ->
      return @_checkIfSegmentsChanged()

    # ====================== fitRows ======================

    _fitRowsReset : ->
      @fitRows = { x: 0, y: 0, height: 0 }

    _fitRowsLayout : ( $elems ) ->
      instance = @
      containerWidth = @element.width()
      props = @fitRows

      $elems.each ->
        $this = $ @
        atomW = $this.outerWidth true
        atomH = $this.outerHeight true

        if props.x isnt 0 and atomW + props.x > containerWidth
          # if this element cannot fit in the current row
          props.x = 0
          props.y = props.height

        # position the atom
        instance._pushPosition $this, props.x, props.y

        props.height = Math.max props.y + atomH, props.height
        props.x += atomW

    _fitRowsGetContainerSize : ->
      return { height : @fitRows.height }

    _fitRowsResizeChanged : ->
      return true

    # ====================== cellsByRow ======================

    _cellsByRowReset : ->
      @cellsByRow = { index: 0 }
      # get this.cellsByRow.columnWidth
      @_getSegments()
      # get this.cellsByRow.rowHeight
      @_getSegments true

    _cellsByRowLayout : ( $elems ) ->
      instance = @
      props = @cellsByRow
      $elems.each ->
        $this = $ @
        col = props.index % props.cols
        row = Math.floor props.index / props.cols
        x = ( col + 0.5 ) * props.columnWidth - $this.outerWidth( true ) / 2
        y = ( row + 0.5 ) * props.rowHeight - $this.outerHeight( true ) / 2
        instance._pushPosition $this, x, y
        props.index++

    _cellsByRowGetContainerSize : ->
      return { height : Math.ceil( @$filteredAtoms.length / @cellsByRow.cols ) * @cellsByRow.rowHeight + @offset.top }

    _cellsByRowResizeChanged : ->
      return @_checkIfSegmentsChanged()

    # ====================== straightDown ======================

    _straightDownReset : ->
      @straightDown = { y : 0 }

    _straightDownLayout : ( $elems ) ->
      instance = @
      $elems.each ( i ) ->
        $this = $ @
        instance._pushPosition $this, 0, instance.straightDown.y
        instance.straightDown.y += $this.outerHeight true

    _straightDownGetContainerSize : ->
      return { height : @straightDown.y }

    _straightDownResizeChanged : ->
      return true

    # ====================== masonryHorizontal ======================

    _masonryHorizontalReset : ->
      # layout-specific props
      @masonryHorizontal = {}
      # FIXME shouldn't have to call this again
      @_getSegments true
      i = @masonryHorizontal.rows
      @masonryHorizontal.rowXs = []
      while ( i-- )
        @masonryHorizontal.rowXs.push 0

    _masonryHorizontalLayout : ( $elems ) ->
      instance = @
      props = instance.masonryHorizontal
      $elems.each ->
        $this = $ @
        # how many rows does this brick span
        rowSpan = Math.ceil $this.outerHeight( true ) / props.rowHeight
        rowSpan = Math.min rowSpan, props.rows

        if rowSpan is 1
          # if brick spans only one column, just like singleMode
          instance._masonryHorizontalPlaceBrick $this, props.rowXs
        else
          # brick spans more than one row
          # how many different places could this brick fit horizontally
          groupCount = props.rows + 1 - rowSpan
          groupX = []

          # for each group potential horizontal position
          for i in [0...groupCount]
            # make an array of colY values for that one group
            groupRowX = props.rowXs.slice i, i+rowSpan
            # and get the max value of the array
            groupX[i] = Math.max.apply Math, groupRowX

          instance._masonryHorizontalPlaceBrick $this, groupX

    _masonryHorizontalPlaceBrick : ( $brick, setX ) ->
      # get the minimum Y value from the columns
      minimumX = Math.min.apply Math, setX
      smallRow = 0
      setXLen = setX.length

      # find index of smallest row, the first from the top
      for set, i in setX
        if set is minimumX
          smallRow = i
          break

      # position the brick
      x = minimumX
      y = @masonryHorizontal.rowHeight * smallRow
      @_pushPosition $brick, x, y

      # apply setHeight to necessary columns
      setWidth = minimumX + $brick.outerWidth true
      setSpan = @masonryHorizontal.rows + 1 - setXLen

      for i in [0...setSpan]
        @masonryHorizontal.rowXs[ smallRow + i ] = setWidth
      return

    _masonryHorizontalGetContainerSize : ->
      containerWidth = Math.max.apply Math, @masonryHorizontal.rowXs
      return { width: containerWidth }

    _masonryHorizontalResizeChanged : ->
      return @_checkIfSegmentsChanged true

    # ====================== fitColumns ======================

    _fitColumnsReset : ->
      @fitColumns = { x: 0, y: 0, width: 0 }

    _fitColumnsLayout : ( $elems ) ->
      instance = @
      containerHeight = @element.height()
      props = @fitColumns
      $elems.each ->
        $this = $ @
        atomW = $this.outerWidth true
        atomH = $this.outerHeight true

        if props.y isnt 0 and atomH + props.y > containerHeight
          # if this element cannot fit in the current column
          props.x = props.width
          props.y = 0

        # position the atom
        instance._pushPosition $this, props.x, props.y

        props.width = Math.max props.x + atomW, props.width
        props.y += atomH

    _fitColumnsGetContainerSize : ->
      return { width : @fitColumns.width }

    _fitColumnsResizeChanged : ->
      return true

    # ====================== cellsByColumn ======================

    _cellsByColumnReset : ->
      @cellsByColumn = { index : 0 }
      # get this.cellsByColumn.columnWidth
      @_getSegments()
      # get this.cellsbyColumn.rowHeight
      @_getSegments true

    _cellsByColumnLayout : ( $elems ) ->
      instance = @
      props = @cellsByColumn
      $elems.each ->
        $this = $ @
        col = Math.floor props.index / props.rows
        row = props.index % props.rows
        x = ( col + 0.5 ) * props.columnWidth - $this.outerWidth( true ) / 2
        y = ( row + 0.5 ) * props.rowHeight - $this.outerHeight( true ) / 2
        instance._pushPosition $this, x, y
        props.index++

    _cellsByColumnGetContainerSize : ->
      return { width : Math.ceil( @$filteredAtoms.length / @cellsByColumn.rows ) * @cellsByColumn.columnWidth }

    _cellsByColumnResizeChanged : ->
      return @_checkIfSegmentsChanged true

    # ====================== straightAcross ======================

    _straightAcrossReset : ->
      @straightAcross = { x : 0 }

    _straightAcrossLayout : ( $elems ) ->
      instance = @
      $elems.each ( i ) ->
        $this = $ @
        instance._pushPosition $this, instance.straightAcross.x, 0
        instance.straightAcross.x += $this.outerWidth true

    _straightAcrossGetContainerSize : ->
      return { width : @straightAcross.x }

    _straightAcrossResizeChanged : ->
      return true
  }

  # =================== imagesLoaded Plugin ===========================

  $.fn.imagesLoaded = ( callback ) ->
    $this = @
    $images = $this.find('img').add( $this.filter('img'))
    len = $images.length
    blank = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='
    loaded = []

    triggerCallback = ->
      callback.call $this, $images

    imgLoaded = ( event ) ->
      img = event.target
      if img.src isnt blank and $.inArray( img, loaded ) is -1
        loaded.push img
        if --len <= 0
          setTimeout triggerCallback
          $images.unbind '.imagesLoaded', imgLoaded

    # if no images, trigger immediatly
    unless len
      triggerCallback()

    $images.bind( 'load.imagesLoaded error.imagesLoaded', imgLoaded ).each ->
      # cached images don't fire load sometimes, so we reset src.
      src = @src
      # webkit hack from http://groups.google.com/group/jquery-dev/browse_thread/thread/eee6ab7b2da50e1f
      # data uri bypasses webkit log warning (thx doug jones)
      @src = blank
      @src = src

    return $this

  # helper function for logging errors
  # $.error breaks jQuery chaining
  logError = ( message ) ->
    if window.console
      window.console.error message

  # =====================  Plugin bridge  =============================

  $.fn.isotope = ( options, callback ) ->
    if typeof options is 'string'
      # call method
      args = Array::slice.call arguments, 1

      @each ->
        instance = $.data @, 'isotope'
        unless instance
          logError( "cannot call methods on isotope prior to initialization; " +
                "attempted to call method '" + options + "'" );
        if not $.isFunction( instance[options] ) or options.charAt(0) is "_"
          logError "no such method '" + options + "' for isotope instance"
        # apply method
        instance[ options ].apply instance, args
    else
      @each ->
        instance = $.data @, 'isotope'
        if instance
          # apply options & init
          instance.option options
          instance._init callback
        else
          # initialize new instance
          $.data @, 'isotope', new $.Isotope( options, @, callback )
    return @
)( window, jQuery )