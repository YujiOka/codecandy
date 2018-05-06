# 提出されたプログラムを実行し、問題との正誤を判断するAPI
require './lib/code_candy/container'

class Api::V1::JudgementController < ApplicationController
  protect_from_forgery except: :exec

  def exec
    # 送られてきたパラメータを変数に格納
    language = params[:language]
    source_code = params[:source_code]
    id = params[:answer_id]

    # コンテナモジュールのインスタンスを生成
    container = CodeCandy::Container.new

    # 問題の標準入出力を呼び出し
    question = Question.find(id)

    # 処理の結果を格納するhash
    result = {}

    # 実行結果を保持しておくフラグ
    answer_flag = true

    question.answers.each do |answer|
      # コンテナに言語、ソースコード、標準入力を与えて提出されたプログラムを実行する
      result = container.init(language, source_code, answer.input)
      result[:stdout] = result[:stdout].force_encoding("UTF-8")

      # 標準出力改行コードを挿入する
      output = answer.output + "\n"

      # 正解だったらanswer_flagをtrueに、違う場合はfalseにしてループを抜ける
      if result[:stdout] == output || result[:stdout] == answer.output
        answer_flag = true
      else
        answer_flag = false
        break
      end
    end

    # result[:answer]に結果を格納する
    if answer_flag
      result[:answer] = "正解"
    else
      result[:answer] = "不正解"
    end

    # submit_programメソッドを呼び出す
    submit_program(source_code, language, id)

    # resultメソッドを呼び出す
    result_submit(answer_flag, id)

    # UTF-8にencodeする
    result[:stdout] = result[:stdout].force_encoding("UTF-8")
    result[:stderr] = result[:stderr].force_encoding("UTF-8")

    render json: result
  end

  private
  # 結果を保存するメソッド
  def result_submit(answer_flag, id)
    @result = Result.new
    @result.user_id = current_user.id
    @result.question_id = id
    if answer_flag
      @result.answer = true
    else
      @result.answer = false
    end
    @result.save
  end

  # 提出されたプログラムを保存するメソッド
  def submit_program(source_code, language, id)
    @question_program = QuestionProgram.new
    @question_program.user_id = current_user.id
    @question_program.question_id = id
    @question_program.language = language
    @question_program.code = source_code
    @question_program.save
  end
end
