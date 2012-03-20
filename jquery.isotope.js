(function() {

  (function(window, $) {
    'use strict';
    var $event, $window, Modernizr, capitalize, classes, document, getStyleProperty, isoContainerStyles, logError, prefixes, result, setIsoTransform, testName, tests, transform2dFns, transform3dFns, transformFnNotations, transformProp, transitionDurProp, transitionEndEvent, transitionProp;
    document = window.document;
    Modernizr = window.Modernizr;
    capitalize = function(str) {
      return str.charAt(0).toUpperCase() + str.slice(1);
    };
    prefixes = 'Moz Webkit O Ms'.split(' ');
    getStyleProperty = function(propName) {
      var prefix, prefixed, style, _i, _len;
      style = document.documentElement.style;
      if (typeof style[propName] === 'string') return propName;
      propName = capitalize(propName);
      for (_i = 0, _len = prefixes.length; _i < _len; _i++) {
        prefix = prefixes[_i];
        prefixed = prefix + propName;
        if (typeof style[prefixed] === 'string') return prefixed;
      }
    };
    transformProp = getStyleProperty('transform');
    transitionProp = getStyleProperty('transitionProperty');
    tests = {
      csstransforms: function() {
        return !!transformProp;
      },
      csstransforms3d: function() {
        var $div, $style, mediaQuery, test, vendorCSSPrefixes;
        test = !!getStyleProperty('perspective');
        if (test) {
          vendorCSSPrefixes = ' -o- -moz- -ms- -webkit- -khtml- '.split(' ');
          mediaQuery = '@media (' + vendorCSSPrefixes.join('transform-3d),(') + 'modernizr)';
          $style = $('<style>' + mediaQuery + '{#modernizr{height:3px}}' + '</style>').appendTo('head');
          $div = $('<div id="modernizr" />').appendTo('html');
          test = $div.height() === 3;
          $div.remove();
          $style.remove();
        }
        return test;
      },
      csstransitions: function() {
        return !!transitionProp;
      }
    };
    if (Modernizr) {
      for (testName in tests) {
        if (!Modernizr.hasOwnProperty(testName)) {
          Modernizr.addTest(testName, tests[testName]);
        }
      }
    } else {
      Modernizr = window.Modernizr = {
        _version: '1.6ish: miniModernizr for Isotope'
      };
      classes = ' ';
      for (testName in tests) {
        result = tests[testName]();
        Modernizr[testName] = result;
        classes += ' ' + (result ? '' : 'no-') + testName;
      }
      $('html').addClass(classes);
    }
    if (Modernizr.csstransforms) {
      transform3dFns = {
        translate: function(position) {
          return 'translate3d(' + position[0] + 'px, ' + position[1] + 'px, 0) ';
        },
        scale: function(scale) {
          return 'scale3d(' + scale + ', ' + scale + ', 1) ';
        }
      };
      transform2dFns = {
        translate: function(position) {
          return 'translate(' + position[0] + 'px, ' + position[1] + 'px) ';
        },
        scale: function(scale) {
          return 'scale(' + scale + ') ';
        }
      };
      transformFnNotations = Modernizr.csstransforms3d ? transform3dFns : transform2sFns;
      setIsoTransform = function(elem, name, value) {
        var data, fnName, newData, scaleFn, transformObj, transformValue, translateFn, valueFns;
        data = $.data(elem, 'isoTransform') || {};
        newData = {};
        transformObj = {};
        newData[name] = value;
        $.extend(data, newData);
        for (fnName in data) {
          transformValue = data[fnName];
          transformObj[fnName] = transformFnNotations[fnName](transformValue);
        }
        translateFn = transformObj.translate || '';
        scaleFn = transformObj.scale || '';
        valueFns = translateFn + scaleFn;
        $.data(elem, 'isoTransform', data);
        return elem.style[transformProp] = valueFns;
      };
      $.cssNumber.scale = true;
      $.cssHooks.scale = {
        set: function(elem, value) {
          return setIsoTransform(elem, 'scale', value);
        },
        get: function(elem, computed) {
          var transform;
          transform = $.data(elem, 'isoTransform');
          return transform && (transform.scale ? transform.scale : 1);
        }
      };
      $.fx.step.scale = function(fx) {
        return $.cssHooks.scale.set(fx.elem, fx.now + fx.unit);
      };
      $.cssNumber.translate = true;
      $.cssHooks.translate = {
        set: function(elem, value) {
          return setIsoTransform(elem, 'translate', value);
        },
        get: function(elem, computed) {
          var transform;
          transform = $.data(elem, 'isoTransform');
          return transform && (transform.translate ? transform.translate : [0, 0]);
        }
      };
    }
    if (Modernizr.csstransitions) {
      transitionEndEvent = {
        WebkitTransitionProperty: 'webkitTransitionEnd',
        MozTransitionProperty: 'transitionend',
        OTransitionProperty: 'oTransitionEnd',
        transitionProperty: 'transitionEnd'
      }[transitionProp];
      transitionDurProp = getStyleProperty('transitionDuration');
    }
    $event = $.event;
    $event.special.smartresize = {
      setup: function() {
        return $(this).bind("resize", $event.special.smartresize.handler);
      },
      teardown: function() {
        return $(this).unbind("resize", $event.special.smartresize.handler);
      },
      handler: function(event, execAsap) {
        var args, context, resizeTimeout;
        context = this;
        args = arguments;
        event.type = "smartresize";
        if (resizeTimeout) clearTimeout(resizeTimeout);
        return resizeTimeout = setTimeout(function() {
          return jQuery.event.handle.apply(context, args);
        }, execAsap === ("execAsap" ? 0 : 100));
      }
    };
    $.fn.smartresize = function(fn) {
      if (fn) {
        return this.bind("smartresize", fn);
      } else {
        return this.trigger("smartresize", ["execAsap"]);
      }
    };
    $.Isotope = function(options, element, callback) {
      this.element = $(element);
      this._create(options);
      return this._init(callback);
    };
    isoContainerStyles = ['width', 'height'];
    $window = $(window);
    $.Isotope.settings = {
      resizable: true,
      layoutMode: 'masonry',
      containerClass: 'isotope',
      itemClass: 'isotope-item',
      hiddenClass: 'isotope-hidden',
      hiddenStyle: {
        opacity: 0,
        scale: 0.001
      },
      visibleStyle: {
        opacity: 1,
        scale: 1
      },
      containerStyle: {
        position: 'relative',
        overflow: 'hidden'
      },
      animationEngine: 'best-available',
      animationOptions: {
        queue: false,
        duration: 800
      },
      sortBy: 'original-order',
      sortAscending: true,
      resizesContainer: true,
      transformsEnabled: !$.browser.opera,
      itemPositionDataEnabled: false
    };
    $.Isotope.prototype = {
      _create: function(options) {
        var containerStyles, elemStyle, instance, originalOrderSorter, prop, _i, _j, _len, _len2, _ref;
        this.options = $.extend({}, $.Isotope.settings, options);
        this.styleQueue = [];
        this.elemCount = 0;
        elemStyle = this.element[0].style;
        this.originalStyle = {};
        containerStyles = isoContainerStyles.slice(0);
        _ref = this.options.containerStyle;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          prop = _ref[_i];
          containerStyles.push(prop);
        }
        for (_j = 0, _len2 = containerStyles.length; _j < _len2; _j++) {
          prop = containerStyles[_j];
          this.originalStyle[prop] = elemStyle[prop] || '';
        }
        this.element.css(this.options.containerStyle);
        this._updateAnimationEngine();
        this._updateUsingTransforms();
        originalOrderSorter = {
          'original-order': function($elem, inst) {
            inst.elemCount++;
            return inst.elemCount;
          },
          random: function() {
            return Math.random();
          }
        };
        this.options.getSortData = $.extend(this.options.getSortData, originalOrderSorter);
        this.reloadItems();
        this.offset = {
          left: parseInt(this.element.css('padding-left'), 10),
          top: parseInt(this.element.css('padding-top'), 10)
        };
        instance = this;
        setTimeout(function() {
          return instance.element.addClass(instance.options.containerClass);
        }, 0);
        if (this.options.resizable) {
          $window.bind('smartresize.isotope', function() {
            return instance.resize();
          });
        }
        return this.element.delegate('.' + this.options.hiddenClass, 'click', function() {
          return false;
        });
      },
      _getAtoms: function($elems) {
        var $atoms, atomStyle, selector;
        selector = this.options.itemSelector;
        $atoms = selector ? $elems.filter(selector).add($elems.find(selector)) : $elems;
        atomStyle = {
          position: 'absolute'
        };
        if (this.usingTransforms) {
          atomStyle.left = 0;
          atomStyle.top = 0;
        }
        $atoms.css(atomStyle).addClass(this.options.itemClass);
        this.updateSortData($atoms, true);
        return $atoms;
      },
      _init: function(callback) {
        this.$filteredAtoms = this._filter(this.$allAtoms);
        this._sort();
        return this.reLayout(callback);
      },
      option: function(opts) {
        var optionName, updateOptionFn;
        if ($.isPlainObject(opts)) {
          this.options = $.extend(true, this.options, opts);
          for (optionName in opts) {
            updateOptionFn = '_update' + capitalize(optionName);
            if (this[updateOptionFn]) this[updateOptionFn]();
          }
        }
      },
      _updateAnimationEngine: function() {
        var animationEngine, isUsingJQueryAnimation;
        animationEngine = this.options.animationEngine.toLowerCase().replace(/[ _\-]/g, '');
        switch (animationEngine) {
          case 'css':
          case 'none':
            isUsingJQueryAnimation = false;
            break;
          case 'jquery':
            isUsingJQueryAnimation = true;
            break;
          default:
            isUsingJQueryAnimation = !Modernizr.csstransitions;
        }
        this.isUsingJQueryAnimation = isUsingJQueryAnimation;
        return this._updateUsingTransforms();
      },
      _updateTransformsEnabled: function() {
        return this._updateUsingTransforms();
      },
      _updateUsingTransforms: function() {
        var usingTransforms;
        usingTransforms = this.usingTransforms = this.options.transformsEnabled && Modernizr.csstransforms && Modernizr.csstransitions && !this.isUsingJQueryAnimation;
        if (!usingTransforms) {
          delete this.options.hiddenStyle.scale;
          delete this.options.visibleStyle.scale;
        }
        return this.getPositionStyles = usingTransforms ? this._translate : this._positionAbs;
      },
      _filter: function($atoms) {
        var $atomsToHide, $atomsToShow, $hiddenAtoms, filter, hiddenClass, hiddenSelector;
        filter = this.options.filter === '' ? '*' : this.options.filter;
        if (!filter) return $atoms;
        hiddenClass = this.options.hiddenClass;
        hiddenSelector = '.' + hiddenClass;
        $hiddenAtoms = $atoms.filter(hiddenSelector);
        $atomsToShow = $hiddenAtoms;
        if (filter !== '*') {
          $atomsToShow = $hiddenAtoms.filter(filter);
          $atomsToHide = $atoms.not(hiddenSelector).not(filter).addClass(hiddenClass);
          this.styleQueue.push({
            $el: $atomsToHide,
            style: this.options.hiddenStyle
          });
        }
        this.styleQueue.push({
          $el: $atomsToShow,
          style: this.options.visibleStyle
        });
        $atomsToShow.removeClass(hiddenClass);
        return $atoms.filter(filter);
      },
      updateSortData: function($atoms, isIncrementingElemCount) {
        var getSortData, instance;
        instance = this;
        getSortData = this.options.getSortData;
        return $atoms.each(function() {
          var $this, key, sortData;
          $this = $(this);
          sortData = {};
          for (key in getSortData) {
            if ((!isIncrementingElemCount) && key === 'original-order') {
              sortData[key] = $.data(this, 'isotope-sort-data')[key];
            } else {
              sortData[key] = getSortData[key]($this, instance);
            }
          }
          return $.data(this, 'isotope-sort-data', sortData);
        });
      },
      _sort: function() {
        var getSorter, sortBy, sortDir, sortFn;
        sortBy = this.options.sortBy;
        getSorter = this._getSorter;
        sortDir = this.options.sortAscending ? 1 : -1;
        sortFn = function(alpha, beta) {
          var a, b;
          a = getSorter(alpha, sortBy);
          b = getSorter(beta, sortBy);
          if (a === b && sortBy !== 'original-order') {
            a = getSorter(alpha, 'original-order');
            b = getSorter(beta, 'original-order');
          }
          return (a > b ? 1 : a < b ? -1 : 0) * sortDir;
        };
        return this.$filteredAtoms.sort(sortFn);
      },
      _getSorter: function(elem, sortBy) {
        return $.data(elem, 'isotope-sort-data')[sortBy];
      },
      _translate: function(x, y) {
        return {
          translate: [x, y]
        };
      },
      _positionAbs: function(x, y) {
        return {
          left: x,
          top: y
        };
      },
      _pushPosition: function($elem, x, y) {
        var position;
        x = Math.round(x + this.offset.left);
        y = Math.round(y + this.offset.top);
        position = this.getPositionStyles(x, y);
        this.styleQueue.push({
          $el: $elem,
          style: position
        });
        if (this.options.itemPositionDataEnabled) {
          return $elem.data('isotope-item-position', {
            x: x,
            y: y
          });
        }
      },
      layout: function($elems, callback) {
        var containerStyle, layoutMode;
        layoutMode = this.options.layoutMode;
        this['_' + layoutMode + 'Layout']($elems);
        if (this.options.resizesContainer) {
          containerStyle = this['_' + layoutMode + 'GetContainerSize']();
          this.styleQueue.push({
            $el: this.element,
            style: containerStyle
          });
        }
        this._processStyleQueue($elems, callback);
        return this.isLaidOut = true;
      },
      _processStyleQueue: function($elems, callback) {
        var a, animOpts, callbackFn, callbacks, duration, instance, isCallbackTriggered, objStyleFn, onLayout, processor, styleFn, styleObj, testElem, triggerCallbackNow;
        styleFn = !this.isLaidOut ? 'css' : (this.isUsingJQueryAnimation ? 'animate' : 'css');
        animOpts = this.options.animationOptions;
        onLayout = this.options.onLayout;
        objStyleFn = null;
        processor = function(i, obj) {
          return obj.$el[styleFn](obj.style, animOpts);
        };
        if (this._isInserting && this.isUsingJQueryAnimation) {
          processor = function(i, obj) {
            objStyleFn = obj.$el.hasClass('no-transition') ? 'css' : styleFn;
            return obj.$el[objStyleFn](obj.style, animOpts);
          };
        } else if (callback || onLayout || animOpts.complete) {
          isCallbackTriggered = false;
          callbacks = [callback, onLayout, animOpts.complete];
          instance = this;
          triggerCallbackNow = true;
          callbackFn = function() {
            var hollaback, _i, _len;
            if (isCallbackTriggered) return;
            for (_i = 0, _len = callbacks.length; _i < _len; _i++) {
              hollaback = callbacks[_i];
              if (typeof hollaback === 'function') {
                hollaback.call(instance.element, $elems);
              }
            }
            return isCallbackTriggered = true;
          };
          if (this.isUsingJQueryAnimation && styleFn === 'animate') {
            animOpts.complete = callbackFn;
            triggerCallbackNow = false;
          } else if (Modernizr.csstransitions) {
            a = 0;
            testElem = this.styleQueue[0].$el;
            while (!testElem.length) {
              styleObj = this.styleQueue[a++];
              if (!styleObj) return;
              testElem = styleObj.$el;
            }
            duration = parseFloat(getComputedStyle(testElem[0])[transitionDurProp]);
            if (duration > 0) {
              processor = function(i, obj) {
                return obj.$el[styleFn](obj.style, animOpts).one(transitionEndEvent, callbackFn);
              };
              triggerCallbackNow = false;
            }
          }
        }
        $.each(this.styleQueue, processor);
        if (triggerCallbackNow) callbackFn();
        return this.styleQueue = [];
      },
      resize: function() {
        if (this['_' + this.options.layoutMode + 'ResizeChanged']()) {
          return this.reLayout();
        }
      },
      reLayout: function(callback) {
        this['_' + this.options.layoutMode + 'Reset']();
        return this.layout(this.$filteredAtoms, callback);
      },
      addItems: function($content, callback) {
        var $newAtoms;
        $newAtoms = this._getAtoms($content);
        this.$allAtoms = this.$allAtoms.add($newAtoms);
        if (callback) return callback($newAtoms);
      },
      insert: function($content, callback) {
        var instance;
        this.element.append($content);
        instance = this;
        return this.addItems($content, function($newAtoms) {
          var $newFilteredAtoms;
          $newFilteredAtoms = instance._filter($newAtoms);
          instance._addHideAppended($newFilteredAtoms);
          instance._sort();
          instance.reLayout();
          return instance._revealAppended($newFilteredAtoms, callback);
        });
      },
      appended: function($content, callback) {
        var instance;
        instance = this;
        return this.addItems($content, function($newAtoms) {
          instance._addHideAppended($newAtoms);
          instance.layout($newAtoms);
          return instance._revealAppended($newAtoms, callback);
        });
      },
      _addHideAppended: function($newAtoms) {
        this.$filteredAtoms = this.$filteredAtoms.add($newAtoms);
        $newAtoms.addClass('no-trasition');
        this._isInserting = true;
        return this.styleQueue.push({
          $el: $newAtoms,
          style: this.options.hiddenStyle
        });
      },
      _revealAppended: function($newAtoms, callback) {
        var instance;
        instance = this;
        return setTimeout(function() {
          $newAtoms.removeClass('no-transition');
          instance.styleQueue.push({
            $el: $newAtoms,
            style: instance.options.visibleStyle
          });
          instance._isInserting = false;
          return instance._processStyleQueue($newAtoms, callback);
        }, 10);
      },
      reloadItems: function() {
        return this.$allAtoms = this._getAtoms(this.element.children());
      },
      remove: function($content, callback) {
        var instance, removeContent;
        instance = this;
        removeContent = function() {
          instance.$allAtoms = instance.$allAtoms.not($content);
          return $content.remove();
        };
        if ($content.filter(':not(.' + this.options.hiddenClass + ')').length) {
          this.styleQueue.push({
            $el: $content,
            style: this.options.hiddenStyle
          });
          this.$filteredAtoms = this.$filteredAtoms.not($content);
          this._sort();
          return this.reLayout(removeContent, callback);
        } else {
          removeContent();
          if (callback) return callback.call(this.element);
        }
      },
      shuffle: function(callback) {
        this.updateSortData(this.$allAtoms);
        this.options.sortBy = 'random';
        this._sort();
        return this.reLayout(callback);
      },
      destroy: function() {
        var elemStyle, options, prop, usingTransforms;
        usingTransforms = this.usingTransforms;
        options = this.options;
        this.$allAtoms.removeClass(options.hiddenClass + ' ' + options.itemClass).each(function() {
          var style;
          style = this.style;
          style.position = '';
          style.top = '';
          style.left = '';
          style.opacity = '';
          if (usingTransforms) return style[transformProp] = '';
        });
        elemStyle = this.element[0].style;
        for (prop in this.originalStyle) {
          elemStyle[prop] = this.originalStyle[prop];
        }
        this.element.unbind('.isotope').undelegate('.' + options.hiddenClass, 'click').removeClass(options.containerClass).removeData('isotope');
        return $window.unbind('.isotope');
      },
      _getSegments: function(isRows) {
        var containerSize, measure, namespace, segmentSize, segments, segmentsName, size;
        namespace = this.options.layoutMode;
        measure = isRows ? 'rowHeight' : 'columnWidth';
        size = isRows ? 'height' : 'width';
        segmentsName = isRows ? 'rows' : 'cols';
        containerSize = this.element[size]();
        segmentSize = this.options[namespace] && this.options[namespace][measure] || this.$filteredAtoms['outer' + capitalize(size)](true) || containerSize;
        segments = Math.floor(containerSize / segmentSize);
        segments = Math.max(segments, 1);
        this[namespace][segmentsName] = segments;
        return this[namespace][measure] = segmentSize;
      },
      _checkIfSegmentsChanged: function(isRows) {
        var namespace, prevSegments, segmentsName;
        namespace = this.options.layoutMode;
        segmentsName = isRows ? 'rows' : 'cols';
        prevSegments = this[namespace][segmentsName];
        this._getSegments(isRows);
        return this[namespace][segmentsName] !== prevSegments;
      },
      _masonryReset: function() {
        var i;
        this.masonry = {};
        this._getSegments();
        i = this.masonry.cols;
        this.masonry.colYs = [];
        while (i--) {
          this.masonry.colYs.push(0);
        }
      },
      _masonryLayout: function($elems) {
        var instance, props;
        instance = this;
        props = instance.masonry;
        return $elems.each(function() {
          var $this, colSpan, groupColY, groupCount, groupY, i;
          $this = $(this);
          colSpan = Math.ceil($this.outerWidth(true) / props.columnWidth);
          colSpan = Math.min(colSpan, props.cols);
          if (colSpan === 1) {
            return instance._masonryPlaceBrick($this, props.colYs);
          } else {
            groupCount = props.cols + 1 - colSpan;
            groupY = [];
            for (i = 0; 0 <= groupCount ? i < groupCount : i > groupCount; 0 <= groupCount ? i++ : i--) {
              groupColY = props.colYs.slice(i, i + colSpan);
              groupY[i] = Math.max.apply(Math, groupColY);
            }
            return instance._masonryPlaceBrick($this, groupY);
          }
        });
      },
      _masonryPlaceBrick: function($brick, setY) {
        var i, minimumY, set, setHeight, setSpan, setYLen, shortCol, x, y, _len;
        minimumY = Math.min.apply(Math, setY);
        shortCol = 0;
        setYLen = setY.length;
        for (i = 0, _len = setY.length; i < _len; i++) {
          set = setY[i];
          if (set === minimumY) {
            shortCol = i;
            break;
          }
        }
        x = this.masonry.columnWidth * shortCol;
        y = minimumY;
        this._pushPosition($brick, x, y);
        setHeight = minimumY + $brick.outerHeight(true);
        setSpan = this.masonry.cols + 1 - setYLen;
        for (i = 0; 0 <= setSpan ? i < setSpan : i > setSpan; 0 <= setSpan ? i++ : i--) {
          this.masonry.colYs[shortCol + i] = setHeight;
        }
      },
      _masonryGetContainerSize: function() {
        var containerHeight;
        containerHeight = Math.max.apply(Math, this.masonry.colYs);
        return {
          height: containerHeight
        };
      },
      _masonryResizeChanged: function() {
        return this._checkIfSegmentsChanged();
      },
      _fitRowsReset: function() {
        return this.fitRows = {
          x: 0,
          y: 0,
          height: 0
        };
      },
      _fitRowsLayout: function($elems) {
        var containerWidth, instance, props;
        instance = this;
        containerWidth = this.element.width();
        props = this.fitRows;
        return $elems.each(function() {
          var $this, atomH, atomW;
          $this = $(this);
          atomW = $this.outerWidth(true);
          atomH = $this.outerHeight(true);
          if (props.x !== 0 && atomW + props.x > containerWidth) {
            props.x = 0;
            props.y = props.height;
          }
          instance._pushPosition($this, props.x, props.y);
          props.height = Math.max(props.y + atomH, props.height);
          return props.x += atomW;
        });
      },
      _fitRowsGetContainerSize: function() {
        return {
          height: this.fitRows.height
        };
      },
      _fitRowsResizeChanged: function() {
        return true;
      },
      _cellsByRowReset: function() {
        this.cellsByRow = {
          index: 0
        };
        this._getSegments();
        return this._getSegments(true);
      },
      _cellsByRowLayout: function($elems) {
        var instance, props;
        instance = this;
        props = this.cellsByRow;
        return $elems.each(function() {
          var $this, col, row, x, y;
          $this = $(this);
          col = props.index % props.cols;
          row = Math.floor(props.index / props.cols);
          x = (col + 0.5) * props.columnWidth - $this.outerWidth(true) / 2;
          y = (row + 0.5) * props.rowHeight - $this.outerHeight(true) / 2;
          instance._pushPosition($this, x, y);
          return props.index++;
        });
      },
      _cellsByRowGetContainerSize: function() {
        return {
          height: Math.ceil(this.$filteredAtoms.length / this.cellsByRow.cols) * this.cellsByRow.rowHeight + this.offset.top
        };
      },
      _cellsByRowResizeChanged: function() {
        return this._checkIfSegmentsChanged();
      },
      _straightDownReset: function() {
        return this.straightDown = {
          y: 0
        };
      },
      _straightDownLayout: function($elems) {
        var instance;
        instance = this;
        return $elems.each(function(i) {
          var $this;
          $this = $(this);
          instance._pushPosition($this, 0, instance.straightDown.y);
          return instance.straightDown.y += $this.outerHeight(true);
        });
      },
      _straightDownGetContainerSize: function() {
        return {
          height: this.straightDown.y
        };
      },
      _straightDownResizeChanged: function() {
        return true;
      },
      _masonryHorizontalReset: function() {
        var i, _results;
        this.masonryHorizontal = {};
        this._getSegments(true);
        i = this.masonryHorizontal.rows;
        this.masonryHorizontal.rowXs = [];
        _results = [];
        while (i--) {
          _results.push(this.masonryHorizontal.rowXs.push(0));
        }
        return _results;
      },
      _masonryHorizontalLayout: function($elems) {
        var instance, props;
        instance = this;
        props = instance.masonryHorizontal;
        return $elems.each(function() {
          var $this, groupCount, groupRowX, groupX, i, rowSpan;
          $this = $(this);
          rowSpan = Math.ceil($this.outerHeight(true) / props.rowHeight);
          rowSpan = Math.min(rowSpan, props.rows);
          if (rowSpan === 1) {
            return instance._masonryHorizontalPlaceBrick($this, props.rowXs);
          } else {
            groupCount = props.rows + 1 - rowSpan;
            groupX = [];
            for (i = 0; 0 <= groupCount ? i < groupCount : i > groupCount; 0 <= groupCount ? i++ : i--) {
              groupRowX = props.rowXs.slice(i, i + rowSpan);
              groupX[i] = Math.max.apply(Math, groupRowX);
            }
            return instance._masonryHorizontalPlaceBrick($this, groupX);
          }
        });
      },
      _masonryHorizontalPlaceBrick: function($brick, setX) {
        var i, minimumX, set, setSpan, setWidth, setXLen, smallRow, x, y, _len;
        minimumX = Math.min.apply(Math, setX);
        smallRow = 0;
        setXLen = setX.length;
        for (i = 0, _len = setX.length; i < _len; i++) {
          set = setX[i];
          if (set === minimumX) {
            smallRow = i;
            break;
          }
        }
        x = minimumX;
        y = this.masonryHorizontal.rowHeight * smallRow;
        this._pushPosition($brick, x, y);
        setWidth = minimumX + $brick.outerWidth(true);
        setSpan = this.masonryHorizontal.rows + 1 - setXLen;
        for (i = 0; 0 <= setSpan ? i < setSpan : i > setSpan; 0 <= setSpan ? i++ : i--) {
          this.masonryHorizontal.rowXs[smallRow + i] = setWidth;
        }
      },
      _masonryHorizontalGetContainerSize: function() {
        var containerWidth;
        containerWidth = Math.max.apply(Math, this.masonryHorizontal.rowXs);
        return {
          width: containerWidth
        };
      },
      _masonryHorizontalResizeChanged: function() {
        return this._checkIfSegmentsChanged(true);
      },
      _fitColumnsReset: function() {
        return this.fitColumns = {
          x: 0,
          y: 0,
          width: 0
        };
      },
      _fitColumnsLayout: function($elems) {
        var containerHeight, instance, props;
        instance = this;
        containerHeight = this.element.height();
        props = this.fitColumns;
        return $elems.each(function() {
          var $this, atomH, atomW;
          $this = $(this);
          atomW = $this.outerWidth(true);
          atomH = $this.outerHeight(true);
          if (props.y !== 0 && atomH + props.y > containerHeight) {
            props.x = props.width;
            props.y = 0;
          }
          instance._pushPosition($this, props.x, props.y);
          props.width = Math.max(props.x + atomW, props.width);
          return props.y += atomH;
        });
      },
      _fitColumnsGetContainerSize: function() {
        return {
          width: this.fitColumns.width
        };
      },
      _fitColumnsResizeChanged: function() {
        return true;
      },
      _cellsByColumnReset: function() {
        this.cellsByColumn = {
          index: 0
        };
        this._getSegments();
        return this._getSegments(true);
      },
      _cellsByColumnLayout: function($elems) {
        var instance, props;
        instance = this;
        props = this.cellsByColumn;
        return $elems.each(function() {
          var $this, col, row, x, y;
          $this = $(this);
          col = Math.floor(props.index / props.rows);
          row = props.index % props.rows;
          x = (col + 0.5) * props.columnWidth - $this.outerWidth(true) / 2;
          y = (row + 0.5) * props.rowHeight - $this.outerHeight(true) / 2;
          instance._pushPosition($this, x, y);
          return props.index++;
        });
      },
      _cellsByColumnGetContainerSize: function() {
        return {
          width: Math.ceil(this.$filteredAtoms.length / this.cellsByColumn.rows) * this.cellsByColumn.columnWidth
        };
      },
      _cellsByColumnResizeChanged: function() {
        return this._checkIfSegmentsChanged(true);
      },
      _straightAcrossReset: function() {
        return this.straightAcross = {
          x: 0
        };
      },
      _straightAcrossLayout: function($elems) {
        var instance;
        instance = this;
        return $elems.each(function(i) {
          var $this;
          $this = $(this);
          instance._pushPosition($this, instance.straightAcross.x, 0);
          return instance.straightAcross.x += $this.outerWidth(true);
        });
      },
      _straightAcrossGetContainerSize: function() {
        return {
          width: this.straightAcross.x
        };
      },
      _straightAcrossResizeChanged: function() {
        return true;
      }
    };
    $.fn.imagesLoaded = function(callback) {
      var $images, $this, blank, imgLoaded, len, loaded, triggerCallback;
      $this = this;
      $images = $this.find('img').add($this.filter('img'));
      len = $images.length;
      blank = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==';
      loaded = [];
      triggerCallback = function() {
        return callback.call($this, $images);
      };
      imgLoaded = function(event) {
        var img;
        img = event.target;
        if (img.src !== blank && $.inArray(img, loaded) === -1) {
          loaded.push(img);
          if (--len <= 0) {
            setTimeout(triggerCallback);
            return $images.unbind('.imagesLoaded', imgLoaded);
          }
        }
      };
      if (!len) triggerCallback();
      $images.bind('load.imagesLoaded error.imagesLoaded', imgLoaded).each(function() {
        var src;
        src = this.src;
        this.src = blank;
        return this.src = src;
      });
      return $this;
    };
    logError = function(message) {
      if (window.console) return window.console.error(message);
    };
    return $.fn.isotope = function(options, callback) {
      var args;
      if (typeof options === 'string') {
        args = Array.prototype.slice.call(arguments, 1);
        this.each(function() {
          var instance;
          instance = $.data(this, 'isotope');
          if (!instance) {
            logError("cannot call methods on isotope prior to initialization; " + "attempted to call method '" + options + "'");
          }
          if (!$.isFunction(instance[options]) || options.charAt(0) === "_") {
            logError("no such method '" + options + "' for isotope instance");
          }
          return instance[options].apply(instance, args);
        });
      } else {
        this.each(function() {
          var instance;
          instance = $.data(this, 'isotope');
          if (instance) {
            instance.option(options);
            return instance._init(callback);
          } else {
            return $.data(this, 'isotope', new $.Isotope(options, this, callback));
          }
        });
      }
      return this;
    };
  })(window, jQuery);

}).call(this);
