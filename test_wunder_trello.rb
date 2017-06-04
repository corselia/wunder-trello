require 'test/unit'
require_relative 'wunder_trello'

class TestWunderTrello < Test::Unit::TestCase
  # oh... not beautiful
  wunder_data = {}
  wunder_data["handmade_data"] = [ # should not handmade-data but auto-created-data from json...
    lists: [
      {
        id: 257277209,
        title: "inbox",
      },
      {
        id: 257393205,
        title: "Twitter",
      },
      {
        id: 257406008,
        title: "ゲーム開発",
      },
    ],
    tasks: [
      {
        id: 2723123456,
        completed:  true,
        starred:  true,
        list_id:  257277209,
        title:  "ゲームクリエイターの系譜",
      },
      {
        id:  2723123026,
        completed:  true,
        starred:  false,
        list_id:  257406007,
        title:  "#SummerOfSuikoden",
      },
      {
        id:  2723123457,
        completed:  false,
        starred:  true,
        list_id:  257393205,
        title:  "hello, twitter!",
      },
      {
        id:  2723123458,
        completed:  false,
        starred:  false,
        list_id:  257406008,
        title:  "develop menu screen",
      },
    ],
    notes: [
      {
        content:  "announcement this event",
        task_id:  2723123026,
      },
      {
        content:  "check buttons",
        task_id:  257406008,
      },
    ],
  ]

  test_order = :defined

  def test_initialize(data)
    wunder_trello = WunderTrello.new
    assert_equal true, wunder_trello.lists.is_a?(Array)
    assert_equal true, wunder_trello.tasks.is_a?(Array)
    assert_equal true, wunder_trello.notes.is_a?(Array)
  end

  def test_wunder_json_filename
    assert_equal true, /^wunderlist-.*\.json$/ === Dir.glob("wunderlist-*.json")[0] # magic number
  end

  def test_jsonfile_to_hash
    assert_nothing_raised do
      File.open("wunderlist-test.json") do |file|
        hashed_json = JSON.load(file)
      end
    end
  end

  data do
    wunder_data
  end
  def test_title_of_list(data)
    wunder_trello = WunderTrello.new
    data.each do |each_data|
      each_data[:tasks].each do |task|
        assert_block do
          ret = wunder_trello.title_of_list(task, each_data[:lists])
          ret.is_a?(Hash)
        end
      end
    end
  end

  data do
    wunder_data
  end
  def test_note_content(data)
    wunder_trello = WunderTrello.new
    data.each do |each_data|
      each_data[:tasks].each do |task|
        ret = wunder_trello.note_content(task, each_data[:notes])
        assert_equal true, ret.is_a?(String) || ret.nil?
      end
    end
  end

  data do
    wunder_data
  end
  def test_params(data)
    wunder_trello = WunderTrello.new
    data.each do |each_data|
      @@params = []
      each_data[:tasks].each do |task|
        id_of_list      = wunder_trello.title_of_list(task, each_data[:lists])[:id]
        title_of_list   = wunder_trello.title_of_list(task, each_data[:lists])[:title]
        note_content    = wunder_trello.note_content(task, each_data[:notes])
        task_title      = task[:title]
        task_id         = task[:id]
        task_starred    = task[:starred]
        task_completed  = task[:completed]
        @@params << { id: task_id, title: task_title, list_id: id_of_list, list: title_of_list, note: note_content, star: task_starred, completed: task_completed }
      end
      assert_equal Array, @@params.class
    end
  end

  data do
    row_data = {}
    row_data["text"] = [
      "test_title - (note) Wunderlist is forever!",
      {
        note: "Wunderlist is forever!",
      },
    ]
    row_data["nil"] = [
      "test_title",
      {
        note: nil,
      },
    ]
    row_data["empty"] = [
      "test_title",
      {
        note: "",
      },
    ]
    row_data
  end
  def test_output_row(data)
    expected, test_note = data
    output  = "test_title"
    output += " - (note) #{test_note[:note]}" unless test_note[:note].nil? || test_note[:note] == ""
    assert_equal expected, output
  end

  data do
    linefeed_data = {}
    linefeed_data["cr_and_lf"] = [
      "<br>",
      {
        linefeed: "\r\n",
      },
    ]
    linefeed_data["lf"] = [
      "<br>",
      {
        linefeed: "\r",
      },
    ]
    linefeed_data["cr"] = [
      "<br>",
      {
        linefeed: "\n",
      },
    ]
    linefeed_data
  end
  def test_remove_linefeed(data)
    expected, test_linefeed = data
    assert_equal expected, test_linefeed[:linefeed].gsub(/(\r\n|\r|\n)/, "<br>")
  end

  def test_which_file_to_write
    wunder_trello = WunderTrello.new
    @@params.each do |param|
      extension = ".txt"
      suffix    = param[:completed] == true ? "copmleted_" : "uncompleted_"
      suffix    += param[:star] == true ? "starred" : "unstarred"
      filename  = "#{param[:list]}(#{param[:list_id]}) - #{suffix}#{extension}"
      assert_equal true, /.*(copmleted_starred|copmleted_unstarred|uncompleted_starred|uncompleted_unstarred)\.txt$/ === filename
    end
  end

  data do
    write_data = {}
    write_data["write_contents_data"] = [
      {
        filename: "test_filename.txt",
        row: "Hello, Trello!<br>Goodby and thanks, Wunderlist!",
      },
    ]
    write_data
  end
  def test_write_row(data)
    data.each do |each_data|
      assert_nothing_raised do
        File.open("./#{each_data[:filename]}", "a") do |file|
          file.puts each_data[:row]
        end
      end
      File.delete("./#{each_data[:filename]}")
    end
  end

  def test_mkdir
    dir_path = "./test_dir*"
    assert_nothing_raised do
      Dir.mkdir(dir_path) unless File.exist?(dir_path)
    end
    Dir.rmdir(dir_path)
  end
end
