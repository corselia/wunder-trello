require 'json'

class WunderTrello
  LISTS_KEY_NAME = "lists".freeze
  TASKS_KEY_NAME = "tasks".freeze
  NOTES_KEY_NAME = "notes".freeze

  def initialize
    hashed_json = jsonfile_to_hash
    @lists = hashed_json["data"][LISTS_KEY_NAME]
    @tasks = hashed_json["data"][TASKS_KEY_NAME]
    @notes = hashed_json["data"][NOTES_KEY_NAME]
  end

  def wunder_json_filename
    Dir.glob("wunderlist-*.json")[0] # magic number
  end

  def jsonfile_to_hash
    File.open(wunder_json_filename) do |file|
      hashed_json = JSON.load(file)
    end
  end

  def title_of_list(task, lists)
    params = []
    lists.each do |list| # 'all scanning' isn't awesome
      if list["id"] == task["list_id"]
        return { id: list["id"], title: list["title"] }
      end
    end
    { id: "null", title: "null" } # if relational list with task is nothing
  end

  def note_content(task, notes)
    notes.each do |note| # 'all scanning' isn't awesome
      if note["task_id"] == task["id"]
        return note["content"]
      end
    end
    nil # if relational note with task is nothing
  end

  def params(tasks = @tasks)
    params = []
    tasks.each do |task|
      id_of_list      = title_of_list(task, @lists)[:id]
      title_of_list   = title_of_list(task, @lists)[:title]
      note_content    = note_content(task, @notes)
      task_title      = task["title"]
      task_id         = task["id"]
      task_starred    = task["starred"]
      task_completed  = task["completed"]
      params << { id: task_id, title: task_title, list_id: id_of_list, list: title_of_list, note: note_content, star: task_starred, completed: task_completed }
    end
    params
  end

  def output_row(param)
    output  = "#{param[:title]}"
    output += " - (note) #{param[:note]}" unless param[:note].nil? || param[:note] == ""
    output
  end

  def remove_linefeed(str)
    str.gsub(/(\r\n|\r|\n)/, "<br>")
  end

  def which_file_to_write(param)
    extension = ".txt"
    suffix    = param[:completed] == true ? "copmleted_" : "uncompleted_"
    suffix    += param[:star] == true ? "starred" : "unstarred"
    filename  = "#{param[:list]}(#{param[:list_id]}) - #{suffix}#{extension}"
  end

  def write_row(filename, row)
    File.open("./#{filename}", "a") do |file|
      file.puts row
    end
  end

  def mkdir(dirname)
    Dir.mkdir("./#{dirname}") unless File.exist?("./#{dirname}")
  end

  def main
    wunder_trello = WunderTrello.new
    dirname = "wunder_trello"
    wunder_trello.mkdir(dirname)

    params = wunder_trello.params
    params.each do |param|
      filename    = wunder_trello.which_file_to_write(param)
      output_row  = wunder_trello.remove_linefeed(wunder_trello.output_row(param))
      wunder_trello.write_row("./#{dirname}/#{filename}", output_row)
    end
  end
end
