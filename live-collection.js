(function() {
  var LiveCollection, LiveModel, LiveRender, LiveWrapper, demandLiveModel, numberKeyCodes,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  this.liveCollection = function(options) {
    return new LiveCollection(options);
  };

  demandLiveModel = function(item) {
    if (!item.isLiveModel) {
      throw new Error("Not a valid item");
    }
  };

  LiveCollection = (function() {
    function LiveCollection(options, crud) {
      if (options == null) {
        options = {};
      }
      this.crud = crud;
      _.extend(this, options);
      _.extend(this, Backbone.Events);
      this.items = [];
      this.byId = {};
      if (options.items != null) {
        this.reset(options.items, options.preSorted);
      }
      if (this.workflowVersion == null) {
        this.workflowVersion = 0;
      }
      this.queueById = {};
      this.lastUpdates = [];
      this.isRunning = false;
      this.debounceSave = _.debounce(this.save, 100);
    }

    LiveCollection.prototype.comparator = function(a, b) {
      return 0;
    };

    LiveCollection.prototype.belongs = function(o) {
      return true;
    };

    LiveCollection.prototype.isFresher = function(candidate, current) {
      return true;
    };

    LiveCollection.prototype.refresh = function() {
      F.demandFunction(this.doRefresh, 'doRefresh');
      return this.doRefresh(item, _.bind(this.finishRefresh, this));
    };

    LiveCollection.prototype.finishRefresh = function(items) {
      return F.demandGoodArray(items, 'items');
    };

    LiveCollection.prototype.create = function() {
      F.demandFunction(this.doCreate, 'doCreate');
      return this.doCreate(item, _.bind(this.finishCreate, this));
    };

    LiveCollection.prototype.finishCreate = function(item) {
      return this.merge(item);
    };

    LiveCollection.prototype["delete"] = function(id) {
      var item;
      F.demandGoodNumber(id, 'id');
      F.demandFunction(this.doDelete, 'doDelete');
      item = this.get({
        id: id
      });
      this.trigger('delete:start', item);
      return this.doDelete(item, _.bind(this.finishDelete, this, item));
    };

    LiveCollection.prototype.finishDelete = function(item, workflowVersion) {
      F.demandGoodNumber(workflowVersion, 'workflowVersion');
      this.remove(item);
      this.workflowVersion++;
      this.trigger("workflowVersion:change", this.workflowVersion);
      this.checkWorkflowVersion(workflowVersion);
      return this.trigger('delete:done', workflowVersion);
    };

    LiveCollection.prototype.queue = function(item) {
      F.demandGoodObject(item, 'item');
      demandLiveModel(item);
      this.queueById[item.id] = item;
      return this.debounceSave();
    };

    LiveCollection.prototype.save = function() {
      var changes, item, _i, _len, _ref;
      F.demandFunction(this.doSave, 'doSave');
      if (_.isEmpty(this.queueById) || this.isRunning) {
        return;
      }
      this.lastUpdates = [];
      _ref = _.values(this.queueById);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (!item.isDirty()) {
          continue;
        }
        changes = item.changes();
        changes.id = item.id;
        this.lastUpdates.push(changes);
      }
      this.queueById = {};
      if (_.isEmpty(this.lastUpdates)) {
        return;
      }
      this.isRunning = true;
      this.trigger("save:start", this.lastUpdates);
      return this.doSave(this.lastUpdates, _.bind(this.finishSave, this));
    };

    LiveCollection.prototype.finishSave = function(itemsById, workflowVersion) {
      F.demandGoodObject(itemsById, 'itemsById');
      F.demandGoodNumber(workflowVersion, 'workflowVersion');
      _.each(this.lastUpdates, (function(_this) {
        return function(changes) {
          var item, responseItem;
          item = _this.byId[changes.id];
          responseItem = itemsById[changes.id];
          _.extend(item.previousValues, changes.newValues);
          responseItem.id = changes.id;
          return _this.merge(responseItem);
        };
      })(this));
      this.isRunning = false;
      this.workflowVersion++;
      this.trigger("workflowVersion:change", this.workflowVersion);
      this.checkWorkflowVersion(workflowVersion);
      this.trigger("save:done", this.workflowVersion);
      return this.debounceSave();
    };

    LiveCollection.prototype.checkWorkflowVersion = function(workflowVersion) {
      F.demandGoodNumber(workflowVersion, 'workflowVersion');
      if (workflowVersion > this.workflowVersion) {
        return this.refresh(workflowVersion);
      }
      return true;
    };

    LiveCollection.prototype._preAdd = function(obj) {
      F.demandGoodObject(obj, 'obj');
      if (!obj.isLiveModel) {
        return liveModel(obj, this);
      }
      if (obj.liveCollection === this) {
        return obj;
      }
      return liveModel(_.pick(obj, obj.attributes), this);
    };

    LiveCollection.prototype._compare = function(a, b) {
      return this.comparator.call(this, a, b) || this.comparePrimitive(a.id, b.id);
    };

    LiveCollection.prototype.comparePrimitive = function(a, b) {
      if (_.isString(a) && _.isString(b)) {
        a = a.toLowerCase();
        b = b.toLowerCase();
      }
      if (a.valueOf() === b.valueOf()) {
        return 0;
      }
      if (a < b) {
        return -1;
      } else {
        return 1;
      }
    };

    LiveCollection.prototype.reset = function(items) {
      var c, o, _i, _len;
      if (!_.isArray(items)) {
        throw new Error('items must be an array');
      }
      this.items = [];
      this.byId = {};
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        o = items[_i];
        if (!this.belongs(o)) {
          continue;
        }
        o = this._preAdd(o);
        this.byId[o.id] = o;
        this.items.push(o);
      }
      c = _.bind(this.comparator, this);
      this.items.sort(c);
      this.trigger("reset", this.items, this.items.length);
      this.trigger("count", this.items.length);
      return this;
    };

    LiveCollection.prototype.merge = function(data) {
      var obj, _i, _len;
      if (_.isArray(data)) {
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          obj = data[_i];
          this._mergeOne(obj);
        }
      } else if (_.isObject(data)) {
        this._mergeOne(data);
      } else {
        throw new Error('Data must be either an array or an object');
      }
      return this;
    };

    LiveCollection.prototype._mergeOne = function(o) {
      var current, idx;
      if (o.id == null) {
        throw new Error("id must not be nil");
      }
      current = this.byId[o.id];
      if (current != null) {
        return this._update(o, current);
      } else {
        if (!this.belongs(o)) {
          return;
        }
        o = this._preAdd(o);
        this.byId[o.id] = o;
        idx = this.binarySearch(o);
        this.items.splice(idx, 0, o);
        this.trigger("add", o, idx);
        return this.trigger("count", this.items.length);
      }
    };

    LiveCollection.prototype._update = function(fresh, current) {
      var attr, idxCurrent, updated, _i, _len, _ref;
      if (!this.isFresher(fresh, current)) {
        return;
      }
      idxCurrent = this.binarySearch(current);
      updated = false;
      _ref = current.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (current[attr] === fresh[attr]) {
          continue;
        }
        updated = true;
        current.setValue(attr, fresh[attr]);
      }
      if (!updated) {
        return;
      }
      if (!this.belongs(current)) {
        return this.remove(current, idxCurrent);
      }
      if (this.hasRightIndex(current, idxCurrent)) {
        return this.trigger("update", current, idxCurrent);
      } else {
        this.remove(current, idxCurrent);
        return this.merge(current);
      }
    };

    LiveCollection.prototype.indexOf = function(e) {
      var obj;
      obj = this.get(e);
      return this.binarySearch(obj);
    };

    LiveCollection.prototype.get = function(e) {
      var obj;
      obj = this.tryGet(e);
      if (obj != null) {
        return obj;
      }
      throw new Error("Did not find object or id " + (JSON.stringify(e)));
    };

    LiveCollection.prototype.tryGet = function(e) {
      var id, _ref;
      id = (_ref = e.id) != null ? _ref : e;
      return this.byId[id];
    };

    LiveCollection.prototype.binarySearch = function(obj) {
      var cmp, left, mid, right;
      if (this.items.length === 0) {
        return 0;
      }
      left = 0;
      right = this.items.length - 1;
      while (left <= right) {
        mid = (left + right) >> 1;
        cmp = this._compare(obj, this.items[mid]);
        if (cmp > 0) {
          left = mid + 1;
        }
        if (cmp < 0) {
          right = mid - 1;
        }
        if (cmp === 0) {
          return mid;
        }
      }
      if (cmp > 0) {
        return mid + 1;
      } else {
        return mid;
      }
    };

    LiveCollection.prototype.hasRightIndex = function(obj, idx) {
      if (idx > 0) {
        if (this._compare(this.items[idx - 1], obj) >= 0) {
          return false;
        }
      }
      if (idx < this.items.length - 1) {
        if (this._compare(obj, this.items[idx + 1]) >= 0) {
          return false;
        }
      }
      return true;
    };

    LiveCollection.prototype.remove = function(e, index) {
      var obj;
      obj = this.tryGet(e);
      if (obj == null) {
        return;
      }
      if (index == null) {
        index = this.binarySearch(obj);
      }
      delete this.byId[obj.id];
      this.items.splice(index, 1);
      this.trigger("remove", obj, index);
      this.trigger("count", this.items.length);
      obj.destroy();
      return this;
    };

    return LiveCollection;

  })();

  this.liveCollection.Class = LiveCollection;

  this.liveModel = function(data, collection) {
    return new LiveModel(data, collection);
  };

  LiveModel = (function() {
    function LiveModel(originalData, liveCollection) {
      var _ref, _ref1;
      this.originalData = originalData;
      this.liveCollection = liveCollection;
      F.demandGoodObject(this.originalData, 'originalData');
      F.demandGoodNumber(this.originalData.id, 'originalData.id');
      F.demandGoodObject(this.liveCollection, 'liveCollection');
      this.attributes = (_ref = this.liveCollection.attributes) != null ? _ref : _.keys(this.originalData);
      this.attributeConfig = (_ref1 = this.liveCollection.attributeConfig) != null ? _ref1 : {};
      _.extend(this, _.pick(this.originalData, this.attributes));
      this.previousValues = {};
      this.liveWrappers = [];
      this.refresh();
      this.isLiveModel = true;
    }

    LiveModel.prototype.refresh = function() {
      return this.previousValues = _.pick(this, this.attributes);
    };

    LiveModel.prototype.initWrappers = function(lastSelector) {
      var container, _i, _len, _ref;
      this.lastSelector = lastSelector;
      F.demandGoodString(this.lastSelector, 'lastSelector');
      this.resetWrappers();
      _ref = $(this.lastSelector);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        container = _ref[_i];
        this.wrap($(container));
      }
    };

    LiveModel.prototype.wrap = function($container) {
      var lw;
      lw = liveWrapper($container, this.attributes);
      this.liveWrappers.push(lw);
      this.bindEvents(lw);
      this.forcePopulate(lw);
      return lw;
    };

    LiveModel.prototype.resetWrappers = function() {
      return this.liveWrappers = [];
    };

    LiveModel.prototype.getWrapper = function($container) {
      var $containers, lw, _i, _len, _ref;
      $containers = this.$();
      _ref = this.liveWrappers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lw = _ref[_i];
        if ($containers.index(lw.$) === $containers.index($container)) {
          return lw;
        }
      }
      throw new Error("Wrapper not found for " + $container);
    };

    LiveModel.prototype.forcePopulate = function(lw) {
      F.demandGoodObject(lw, 'lw');
      return lw.populate(_.pick(this, this.attributes));
    };

    LiveModel.prototype.forcePopulateAll = function() {
      var lw, values, _i, _len, _ref, _results;
      values = _.pick(this, this.attributes);
      _ref = this.liveWrappers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lw = _ref[_i];
        _results.push(lw.populate(values));
      }
      return _results;
    };

    LiveModel.prototype.$ = function() {
      var $dom, lw, _i, _len, _ref;
      $dom = $();
      if (this.liveWrappers.length === 0) {
        return $dom;
      }
      _ref = this.liveWrappers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lw = _ref[_i];
        $dom = $dom.add(lw.$);
      }
      return $dom;
    };

    LiveModel.prototype.bindEvents = function(lw) {
      var field, name, _ref;
      F.demandGoodObject(lw, 'lw');
      _ref = lw.fields;
      for (name in _ref) {
        field = _ref[name];
        field.on("keyup", _.bind(this.onFieldKeyUp, this));
        field.on("change", _.bind(this.onFieldChange, this));
      }
    };

    LiveModel.prototype.onFieldKeyUp = function(ev) {
      return this.setValue(ev.currentTarget.name, $(ev.currentTarget).val());
    };

    LiveModel.prototype.onFieldChange = function(ev) {
      var $item, name, val;
      F.demandFunction(ev.preventDefault, 'ev.preventDefault');
      ev.preventDefault();
      $item = $(ev.currentTarget).closest("[data-rowid]");
      name = ev.currentTarget.name;
      val = $(ev.currentTarget).val();
      return this.setValue(name, val);
    };

    LiveModel.prototype.setValue = function(attribute, val) {
      var hasChanged;
      F.demandGoodString(attribute, 'attribute');
      val = this.sanitizeValue(attribute, val);
      hasChanged = this[attribute] !== val;
      this[attribute] = val;
      if (hasChanged) {
        this.liveCollection.trigger("model:change", attribute, val, this);
        this.liveCollection.queue(this);
      }
      return this.setValueInWrappers(attribute, val);
    };

    LiveModel.prototype.setValues = function(values) {
      var key, val, _results;
      F.demandGoodObject(values, 'values');
      _results = [];
      for (key in values) {
        val = values[key];
        _results.push(this.setValue(key, val));
      }
      return _results;
    };

    LiveModel.prototype.setValueInWrappers = function(attribute, value) {
      var lw, _i, _len, _ref;
      _ref = this.liveWrappers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lw = _ref[_i];
        if (lw.fields[attribute]) {
          lw.fields[attribute].val(value);
          continue;
        }
        if (lw.textFields[attribute]) {
          lw.textFields[attribute].html(value);
        }
      }
    };

    LiveModel.prototype.sanitizeValue = function(attribute, value) {
      F.demandGoodString(attribute, 'attribute');
      return value;
    };

    LiveModel.prototype.applyChanges = function() {
      var attr, lw, values, _i, _j, _len, _len1, _ref, _ref1, _results;
      values = {};
      _ref = this.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (this[attr] !== this.previousValues[attr]) {
          values[attr] = this[attr];
        }
      }
      if (_.isEmpty(values)) {
        return;
      }
      _ref1 = this.liveWrappers;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        lw = _ref1[_j];
        _results.push(lw.populate(values));
      }
      return _results;
    };

    LiveModel.prototype.isDirty = function() {
      return this.dirtyAttributes().length > 0;
    };

    LiveModel.prototype.dirtyAttributes = function() {
      var attr, dirtyAttributes, _i, _len, _ref;
      dirtyAttributes = [];
      _ref = this.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (this[attr] !== this.previousValues[attr]) {
          dirtyAttributes.push(attr);
        }
      }
      return dirtyAttributes;
    };

    LiveModel.prototype.changes = function() {
      var changes, dirtyAttributes, key, pv, val, _i, _len, _ref;
      dirtyAttributes = this.dirtyAttributes();
      changes = {
        id: this.id,
        newValues: _.pick(this, dirtyAttributes),
        previousValues: _.pick(this.previousValues, dirtyAttributes)
      };
      _ref = changes.newValues;
      for (val = _i = 0, _len = _ref.length; _i < _len; val = ++_i) {
        key = _ref[val];
        pv = changes.previousValues[key];
        changes.newValues[key] = this.sanitizeValue(key, val);
        changes.previousValues[key] = this.sanitizeValue(key, pv);
      }
      return changes;
    };

    LiveModel.prototype.destroy = function() {
      var lw, _i, _len, _ref;
      _ref = this.liveWrappers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        lw = _ref[_i];
        lw.destroy();
      }
      return delete this;
    };

    return LiveModel;

  })();

  this.liveModel.Class = LiveModel;

  this.liveRender = function(options) {
    return new LiveRender(options);
  };

  LiveRender = (function() {
    function LiveRender(options) {
      var template, tplContents, variable, _ref;
      if (options == null) {
        options = {};
      }
      if (this.render == null) {
        tplContents = $(options.template).html();
        variable = (_ref = options.templateVariable) != null ? _ref : "data";
        template = _.template(tplContents, null, {
          variable: variable
        });
        this.render = function(data) {
          return template(data);
        };
      }
      this.container = $(options.container);
      this.lc = options.liveCollection;
      this.lc.on("add", this.add, this);
      this.lc.on("remove", this.remove, this);
      this.lc.on("reset", this.reset, this);
      if (_.isFunction(options.onCount)) {
        this.lc.on("count", options.onCount, this);
      }
      if (_.isFunction(options.onClick)) {
        this.container.on("click", (function(_this) {
          return function(event) {
            return _this.click(event, options.onClick);
          };
        })(this));
      }
    }

    LiveRender.prototype.click = function(e, handler) {
      var container, id, item, msg;
      container = $(e.target).closest("[data-rowid]");
      if (container.length === 0) {
        msg = "Unable to find containing element for click. You must render each data row " + 'within an HTML element with a "data-rowid" attribute';
        throw new Error(msg);
      }
      if (container.length > 1) {
        throw new Error('Found multiple containing elements for click');
      }
      id = Number(container.data("rowid"));
      item = this.lc.get(id);
      return handler(item, e);
    };

    LiveRender.prototype.add = function(item, index) {
      var $el, html;
      html = this.render(item).trim();
      $el = $(html).hide();
      if (0 === index) {
        $el.prependTo(this.container).fadeIn();
      } else {
        $el.insertAfter(this.container.children().eq(index - 1)).fadeIn();
      }
      return item.wrap($el.find("[data-rowid='" + item.id + "']"));
    };

    LiveRender.prototype.update = function(item) {
      var html, index;
      index = this.lc.binarySearch(item);
      html = this.render(item).trim();
      return this.container.children().eq(index).replaceWith(html);
    };

    LiveRender.prototype.remove = function(item, index) {
      var $el, wrapper;
      $el = this.container.children().eq(index);
      wrapper = item.getWrapper($el);
      return wrapper.destroy();
    };

    LiveRender.prototype.reset = function(items) {
      var html, item, _i, _len, _results;
      this.container.html("");
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        html = this.render(item);
        this.container.append(html);
        _results.push(item.wrap(this.container.find("[data-rowid='" + item.id + "']")));
      }
      return _results;
    };

    LiveRender.prototype.count = function(count) {
      return this.count.text(count);
    };

    return LiveRender;

  })();

  this.liveRender.Class = LiveRender;

  this.liveWrapper = function($container, attributes, attributeConfig) {
    return new LiveWrapper($container, attributes, attributeConfig);
  };

  numberKeyCodes = [188, 190, 8, 9, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 110];

  LiveWrapper = (function() {
    function LiveWrapper($, attributes, attributeConfig) {
      var $field, $textField, attribute, _i, _len, _ref;
      this.$ = $;
      this.attributes = attributes;
      this.attributeConfig = attributeConfig != null ? attributeConfig : {};
      this.onFieldKeyDown = __bind(this.onFieldKeyDown, this);
      this.onFieldFocus = __bind(this.onFieldFocus, this);
      F.demandArrayOfGoodStrings(this.attributes, 'attributes');
      this.fields = {};
      this.textFields = {};
      _ref = this.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attribute = _ref[_i];
        $field = this.$.find("[name='" + attribute + "']");
        $textField = this.$.find("." + attribute);
        if ($field.length > 0) {
          this.fields[attribute] = $field;
          continue;
        }
        if ($textField.length > 0) {
          this.textFields[attribute] = $textField;
        }
      }
      this.bindEvents();
    }

    LiveWrapper.prototype.bindEvents = function() {
      var $field, name, _ref;
      _ref = this.fields;
      for (name in _ref) {
        $field = _ref[name];
        $field.on("keydown", this.onFieldKeyDown);
        $field.on('focus', this.onFieldFocus);
      }
    };

    LiveWrapper.prototype.onFieldFocus = function(ev) {
      var $el, _ref;
      $el = $(ev.currentTarget);
      if ((_ref = ev.currentTarget.name, __indexOf.call(this.attributeConfig.numbers, _ref) >= 0)) {
        if (Number($el.val()) === 0) {
          return $el.val("");
        }
      }
    };

    LiveWrapper.prototype.onFieldKeyDown = function(ev) {
      var _ref, _ref1;
      F.demandGoodNumber(ev.keyCode, 'ev.keyCode');
      F.demandFunction(ev.preventDefault, 'ev.preventDefault');
      if ((_ref = ev.currentTarget.name, __indexOf.call(this.attributeConfig.numbers, _ref) >= 0)) {
        if ((_ref1 = ev.keyCode, __indexOf.call(numberKeyCodes, _ref1) < 0)) {
          return ev.preventDefault();
        }
      }
    };

    LiveWrapper.prototype.populate = function(values) {
      var key, value;
      for (key in values) {
        value = values[key];
        if ((this.fields[key] != null)) {
          this.fields[key].val(value);
        }
        if ((this.textFields[key] != null)) {
          this.textFields[key].html(value);
        }
      }
    };

    LiveWrapper.prototype.destroy = function() {
      return this.$.remove();
    };

    return LiveWrapper;

  })();

  this.liveWrapper.Class = LiveWrapper;

}).call(this);
