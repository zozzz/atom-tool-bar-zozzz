GitRepoSelector = require "./git-repo-selector"
path = require "path"

UNGIT_URI = "ungit://ungit-URI"

module.exports = AtomToolBarZozzz =
	toolBar: null
	subscriptions: null

	has_gitrepo: false
	has_activeEditor: false
	has_gitRepoForEditor: false

	activate: (state) ->
		@subscriptions = atom.commands.add "atom-workspace", "atom-tool-bar-zozzz:ungit-toggle": =>
			@selectGitRepo (repo) =>
				@toggleUngit(@_SelectedRepo = repo)

		atom.commands.add "atom-workspace", "atom-tool-bar-zozzz:merge-conflicts-detect": =>
			@selectGitRepo (repo) =>
				@mergeConflicts(repo)

		@subscriptions.add atom.workspace.onDidOpen (event) =>
			if event.item?.uri == UNGIT_URI
				if @_SelectedRepo
					setTimeout (=>
						event.item.loadPath(@_SelectedRepo.repo.workingDirectory)
					), 50

		@subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
			if item?.uri == UNGIT_URI
				if @_SelectedRepo
					setTimeout (=>
						item.loadPath(@_SelectedRepo.repo.workingDirectory)
					), 50

		@subscriptions.add atom.project.onDidChangePaths (paths) =>
			@reloadToolbar()

		@subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
			@reloadToolbar()

	deactivate: ->
		@subscriptions.dispose()
		@toolBar?.removeItems()

	serialize: ->

	toggle: ->

	consumeToolBar: (toolBar) ->
		@toolBar = toolBar 'atom-tool-bar-zozzz'
		@reloadToolbar()

	reloadToolbar: () ->
		return if not @toolBar

		@testRequirements().then (changed) =>
			return if not changed

			@toolBar.removeItems()
			@toolBar.addButton
				tooltip: 'List projects'
				callback: 'project-manager:list-projects'
				icon: 'file-submodule'
			@toolBar.addButton
				tooltip: 'Open Folder'
				callback: 'application:open-folder'
				icon: 'folder'
				iconset: 'ion'
			@toolBar.addButton
				tooltip: 'Add Folder'
				callback: 'application:add-project-folder'
				icon: 'medkit'
				iconset: 'ion'

			if @has_gitrepo
				@toolBar.addSpacer()
				@toolBar.addButton
					icon: "repo"
					callback: "atom-tool-bar-zozzz:ungit-toggle"
					tooltip: "UNGIT"
				@toolBar.addButton
					tooltip: 'Merge Conflicts'
					callback: 'atom-tool-bar-zozzz:merge-conflicts-detect'
					icon: 'code-fork'
					iconset: 'fa'

				if @has_gitRepoForEditor
					@toolBar.addButton
						tooltip: 'History'
						callback: 'git-history:show-file-history'
						icon: 'history'
						iconset: "mdi"

			if @has_activeEditor
				@toolBar.addSpacer()
				@toolBar.addButton
					icon: "align-right"
					callback: "tabs-to-spaces:untabify-all"
					tooltip: "Tabs -> spaces"
					iconset: "fi"
				@toolBar.addButton
					icon: "indent-more"
					callback: "tabs-to-spaces:tabify"
					tooltip: "Spaces -> tabs"
					iconset: "fi"
				@toolBar.addButton
					icon: "format-float-left"
					callback: "atom-beautify:beautify-editor"
					tooltip: "Beautify editor"
					iconset: "mdi"
				@toolBar.addButton
					icon: "eye"
					callback: "window:toggle-invisibles"
					tooltip: "Toggle invisibles"
					iconset: "ion"

			if atom.inDevMode()
				@toolBar.addSpacer()

				@toolBar.addButton
					icon: "refresh"
					callback: "window:reload"
					tooltip: "Reload Window"
					iconset: "ion"


	collectGitRepos: () ->
		return Promise.all(atom.project.getDirectories().map(atom.project.repositoryForDirectory.bind(atom.project))).then (repos) ->
			res = []
			for r in repos
				res.push(r) if r
			return res

	selectGitRepo: (cb) ->
		@collectGitRepos().then (repos) =>
			if repos.length
				if repos.length > 1
					x = new GitRepoSelector repos, (selected) =>
						cb(selected)
						# @toggleUngit(@_SelectedRepo = selected)
					x.toggle()
				else
					cb(repos[0])
					# @toggleUngit(@_SelectedRepo = repos[0])

	toggleUngit: (repo) ->
		pane = atom.workspace.paneForURI(UNGIT_URI)
		if pane
			for view, i in pane.items
				if view.uri == UNGIT_URI
					view.loadPath(repo.repo.workingDirectory)
					pane.activateItemAtIndex(i)
					return

		editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
		atom.commands.dispatch(editorElement, "ungit:toggle")

	mergeConflicts: (repo) ->
		@textEditorForRepo repo, (textEditor) =>
			editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
			atom.commands.dispatch(editorElement, "merge-conflicts:detect")

	textEditorForRepo: (repo, cb) ->
		for pane in atom.workspace.getPanes()
			for view, i in pane.items
				if (p = view.path) and path.normalize(p).indexOf(path.normalize(repo.repo.workingDirectory)) == 0
					pane.activateItemAtIndex(i)
					cb(view)
					return

		atom.workspace.open(repo.repo.workingDirectory + "/.gitignore").then cb

	testRequirements: () ->
		old_activeEditor = @has_activeEditor
		old_gitrepo = @has_gitrepo
		old_gitRepoForEditor = @has_gitRepoForEditor

		return new Promise (resolve) =>
			@has_activeEditor = !!(editor = atom.workspace.getActiveTextEditor())

			@collectGitRepos().then (repos) =>
				@has_gitrepo = repos.length > 0
				@has_gitRepoForEditor = false

				if @has_activeEditor
					for r in repos
						if path.normalize(editor.getPath()).indexOf(path.normalize(r.repo.workingDirectory)) == 0
							@has_gitRepoForEditor = true
							break

				resolve(
					@_firstRun or
					old_activeEditor != @has_activeEditor or
					old_gitrepo != @has_gitrepo or
					old_gitRepoForEditor != @has_gitRepoForEditor
				)
				@_firstRun = false
