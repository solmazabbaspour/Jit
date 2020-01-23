# jit.rb

require "fileutils"
require "pathname"

require_relative "./database"
require_relative "./entry"
require_relative "./tree"
require_relative "./workspace"
require_relative "./author"
require_relative "./commit"

command = ARGV.shift

case command
when "init"
  path = ARGV.fetch(0, Dir.getwd) # Get the location of where to save the repo
  root_path = Pathname.new(File.expand_path(path)) # Make the path absolute
  git_path = root_path.join(".git")

  ["objects", "refs"].each do |dir|
    begin
      FileUtils.mkdir_p(git_path.join(dir)) # Create a folder including any parent dir
    rescue Errno::EACCES => error
      $stderr.puts "fatal: #{error.message}"
      exit 1
    end
  end

  puts "Initialized empty Jit repository in #{git_path}"
  exit 0
when "commit"
  root_path = Pathname.new(Dir.getwd) # Make the path absolute
  git_path = root_path.join(".git")
  db_path = git_path.join("objects")

  workspace = Workspace.new(root_path)
  database = Database.new(db_path)

  entries = Array.new
  workspace.list_files.each do |path|
    data = workspace.read_file(path)
    blob = Blob.new(data)

    database.store(blob)

    entries.push Entry.new(path, blob.oid)
  end

  tree = Tree.new(entries)
  database.store(tree)

  name = ENV.fetch("GIT_AUTHOR_NAME")
  email = ENV.fetch("GIT_AUTHOR_EMAIL")
  author = Author.new(name, email, Time.now)
  message = $stdin.read

  commit = Commit.new(tree.oid, author, message)
  database.store(commit)

  File.open(git_path.join("HEAD"), File::WRONLY | File::CREAT) do |file|
    file.puts(commit.oid)
  end

  puts "[(root-commit) #{ commit.oid }] #{ message.lines.first }"
  exit 0
else
  $stderr.puts "jit: #{ command } is not a jit command."
  exit 1
end
