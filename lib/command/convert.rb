# -*- coding: UTF-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "fileutils"
require_relative "../database"
require_relative "../downloader"
require_relative "../novelconverter"
require_relative "../localsetting"
require_relative "../kindlestrip"

module Command
  class Convert < CommandBase
    @@database = Database.instance

    def oneline_help
      "小説を変換します。管理小説以外にテキストファイルも変換可能"
    end

    def initialize
      super("<target> [<target2> ...] [option]")
      @opt.separator <<-EOS

  ・指定した小説を縦書用に整形及びEPUB、MOBIに変換します。
  ・変換したい小説のNコード、URL、タイトルもしくはIDを指定して下さい。
    IDは #{@opt.program_name} list を参照して下さい。
  ・一度に複数の小説を指定する場合は空白で区切って下さい。
  ※-oオプションがない場合、[変換]小説名.txtが小説の保存フォルダに出力されます
  ・管理小説以外にもテキストファイルを変換出来ます。
    テキストファイルのファイルパスを指定します。
  ※複数指定した場合に-oオプションがあった場合、ファイル名に連番がつきます。
  ・MOBI化する場合は narou setting device=kindle をして下さい。
  ・device=kobo の場合、.kepub.epub を出力します。

  Example:
    narou convert n9669bk
    narou convert http://ncode.syosetu.com/n9669bk/
    narou convert 異世界迷宮で奴隷ハーレムを
    narou convert 1 -o "ハーレム -変換済み-.txt"
    narou convert mynovel.txt --enc sjis

  Options:
      EOS
      @opt.on("-o FILE", "--output FILE", "出力ファイル名を指定する。フォルダパス部分は無視される") { |filename|
        @options["output"] = filename
      }
      @opt.on("-e ENCODING", "--enc ENCODING",
              "テキストファイル指定時の文字コードを指定する。デフォルトはUTF-8") { |encoding|
        encoding = "utf-8" if encoding =~ /UTF8/i
        @options["encoding"] = encoding
      }
      @opt.on("--no-epub", "AozoraEpub3でEPUB化しない") {
        @options["no-epub"] = true
      }
      @opt.on("--no-mobi", "kindlegenでMOBI化しない") {
        @options["no-mobi"] = true
      }
      @opt.on("--no-strip", "MOBIをstripしない") {
        @options["no-strip"] = true
      }
      @opt.on("--no-open", "出力時に保存フォルダを開かない") {
        @options["no-open"] = true
      }
      @opt.on("-i", "--inspect", "小説状態の調査結果を表示する") {
        @options["inspect"] = true
      }
      @opt.on("-v", "--verbose", "AozoraEpub3, kindlegen の標準出力を全て表示します") {
        @options["verbose"] = true
      }
      @opt.separator <<-EOS

  Configuration:
    --no-epub, --no-mobi, --no-strip, --no-open , --inspect は narou setting コマンドで恒常的な設定にすることが可能です。
    convert.copy_to を設定すれば変換したEPUB/MOBIを指定のフォルダに自動でコピー出来ます。
    device で設定した端末が接続されていた場合、対応するデータを自動送信します。
    詳しくは narou setting --help を参照して下さい。
      EOS
    end

    def load_local_settings
      local_settings = LocalSetting.get["local_setting"]
      local_settings.each do |name, value|
        if name =~ /^convert\.(.+)$/
          @options[$1] = value
        end
      end
    end

    def execute(argv)
      load_local_settings    # @opt.on 実行前に設定ロードしたいので super 前で実行する
      super
      if argv.empty?
        puts @opt.help
        return
      end
      @output_filename = @options["output"]
      if @output_filename
        @ext = File.extname(@output_filename)
        @basename = File.basename(@output_filename, @ext)
      else
        @basename = nil
      end
      if @options["encoding"]
        @enc = Encoding.find(@options["encoding"]) rescue nil
        unless @enc
          warn "--enc で指定された文字コードは存在しません。sjis, eucjp, utf-8 等を指定して下さい"
          return
        end
      end
      @device = Narou.get_device
      convert_novels(argv)
    end

    def convert_novels(argv)
      argv.each.with_index(1) do |target, i|
        Helper.print_horizontal_rule if i > 1
        if @basename
          @basename << " (#{i})" if argv.length > 1
          @output_filename = @basename + @ext
        end

        if File.file?(target.to_s)
          @argument_target_type = :file
          res = convert_txt(target)
        else
          @argument_target_type = :novel
          unless Downloader.novel_exists?(target)
            warn "#{target} は存在しません"
            next
          end
          res = NovelConverter.convert(target, @output_filename, @options["inspect"])
        end
        next unless res
        @converted_txt_path = res[:converted_txt_path]
        @use_dakuten_font = res[:use_dakuten_font]

        ebook_file = convert_txt_to_ebook_file
        next if ebook_file.nil?
        if ebook_file
          copied_file_path = copy_to_converted_file(ebook_file)
          if copied_file_path
            puts copied_file_path.encode(Encoding::UTF_8) + " へコピーしました"
          end
          if @device && @device.connecting? && File.extname(ebook_file) == @device.ebook_file_ext
            Send.execute_and_rescue_exit([@device.name, target])
          end
        end

        unless @options["no-open"]
          Helper.open_directory_by_os_filer(File.dirname(@converted_txt_path), "小説の保存フォルダを開きますか")
        end
      end
    rescue Interrupt
      puts
      puts "変換を中断しました"
      exit 1
    end

    def convert_txt(target)
      return NovelConverter.convert_file(target, @enc, @output_filename, @options["inspect"])
    rescue ArgumentError => e
      if e.message =~ /invalid byte sequence in UTF-8/
        warn "#{target}"
        warn "テキストファイルの文字コードがUTF-8ではありません。" +
        "--enc オプションでテキストの文字コードを指定して下さい"
        warn "(#{e.message})"
        return nil
      else
        raise
      end
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
      warn "#{target}"
      warn "テキストファイルの文字コードは#{@options["encoding"]}ではありませんでした。" +
      "正しい文字コードを指定して下さい"
      return nil
    end

    def convert_txt_to_ebook_file
      return false if @options["no-epub"]
      # epub
      status = NovelConverter.txt_to_epub(@converted_txt_path, @use_dakuten_font, nil, @device, @options["verbose"])
      return nil if status != :success
      if @device && @device.kobo?
        epub_ext = @device.ebook_file_ext
      else
        epub_ext = ".epub"
      end
      epub_path = @converted_txt_path.sub(/.txt$/, epub_ext)

      if !@device || !@device.kindle? || @options["no-mobi"]
        return epub_path
      end

      # mobi
      status = NovelConverter.epub_to_mobi(epub_path, @options["verbose"])
      return nil if status != :success
      mobi_path = epub_path.sub(/\.epub$/, @device.ebook_file_ext)

      # strip
      unless @options["no-strip"]
        puts "kindlestrip実行中"
        begin
          SectionStripper.strip(mobi_path, nil, false)
        rescue StripException => e
          warn "Error: #{e.message}"
        end
      end
      puts "MOBIファイルを出力しました"

      return mobi_path
    end

    def copy_to_converted_file(src_path)
      copy_to_dir = @options["copy_to"]
      return nil unless copy_to_dir
      if File.directory?(copy_to_dir)
        FileUtils.copy(src_path, copy_to_dir)
        return File.join(copy_to_dir, File.basename(src_path))
      else
        warn "#{copy_to_dir} はフォルダではないかすでに削除されています。コピー出来ませんでした"
        return nil
      end
    end
  end
end
