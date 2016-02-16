{$, $$, SelectListView, View} = require "atom-space-pen-views"

module.exports =
class GitRepoSelector extends SelectListView
	@select: (items, callback) ->
		selector = new GitRepoSelector(items, callback)
		selector.toggle()

	constructor: (@repos, @_cb) ->
		super()

	initialize: ->
    	super()
    	@addClass("command-palette")

	cancelled: ->
		@hide()

	confirmed: (item) ->
		@cancel()
		@_cb?(item)

	toggle: ->
		# Toggling now checks panel visibility,
		# and hides / shows rather than attaching to / detaching from the DOM.
		if @panel?.isVisible()
			@cancel()
		else
			@show()

	show: ->
		# Now you will add your select list as a modal panel to the workspace
		@panel ?= atom.workspace.addModalPanel(item: this)
		@panel.show()
		@storeFocusedElement()
		@setItems(@repos)
		@focusFilterEditor()

	hide: ->
		@panel?.hide()

	viewForItem: (item) ->
		console.log(item)
		view = $$ ->
			@li class: 'two-lines', =>
				@div class: 'status status-added'
				@div class: 'primary-line icon icon-repo', =>
					@span item.repo.workingDirectory.split(/\/|(\\+)/g).pop()
				@div class: 'secondary-line no-icon', =>
					@span item.repo.workingDirectory
		return view
