GitRepoSelector = require "./git-repo-selector"
path = require "path"

UNGIT_URI = "ungit://ungit-URI"

module.exports = AtomToolBarZozzz =
  toolBar: null

  activate: (state) ->


    atom.commands.add "atom-workspace", "atom-tool-bar-zozzz:ungit-toggle": =>
      @selectGitRepo (repo) =>
        @toggleUngit(@_SelectedRepo = repo)

    atom.commands.add "atom-workspace", "atom-tool-bar-zozzz:merge-conflicts-detect": =>
      @selectGitRepo (repo) =>
        @mergeConflicts(repo)

    atom.workspace.onDidOpen (event) =>
      if event.item?.uri == UNGIT_URI
        if @_SelectedRepo
          setTimeout (=>
            event.item.loadPath(@_SelectedRepo.repo.workingDirectory)
          ), 50

    atom.workspace.onDidChangeActivePaneItem (item) =>
      if item.uri == UNGIT_URI
        if @_SelectedRepo
          setTimeout (=>
            item.loadPath(@_SelectedRepo.repo.workingDirectory)
          ), 50


  deactivate: ->

  serialize: ->

  toggle: ->

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'atom-tool-bar-zozzz'
    @reloadToolbar()

  reloadToolbar: () ->
    @toolBar.addButton
      tooltip: 'List projects'
      callback: 'project-manager:list-projects'
      icon: 'file-submodule'
    @toolBar.addButton
      tooltip: 'Add Folder'
      callback: 'application:add-project-folder'
      icon: 'medkit'
      iconset: 'ion'
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

    @toolBar.addSpacer()

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


