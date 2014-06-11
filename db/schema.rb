# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140514070055) do

  create_table "choices", force: true do |t|
    t.integer  "choice_type"
    t.string   "prompt"
    t.string   "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "difficulty_levels", force: true do |t|
    t.string   "desc"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "question_occurrences", force: true do |t|
    t.integer  "round_id"
    t.integer  "question_id"
    t.integer  "index_in_round"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "question_occurrences", ["question_id"], name: "index_question_occurrences_on_question_id"
  add_index "question_occurrences", ["round_id"], name: "index_question_occurrences_on_round_id"

  create_table "question_types", force: true do |t|
    t.string   "prompt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", force: true do |t|
    t.integer  "choice_type"
    t.string   "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "correct_choice_id"
    t.integer  "close_choice_id"
    t.integer  "question_type_id"
    t.integer  "difficulty_level_id"
  end

  add_index "questions", ["close_choice_id"], name: "index_questions_on_close_choice_id"
  add_index "questions", ["correct_choice_id"], name: "index_questions_on_correct_choice_id"
  add_index "questions", ["difficulty_level_id"], name: "index_questions_on_difficulty_level_id"
  add_index "questions", ["question_type_id"], name: "index_questions_on_question_type_id"

  create_table "results", force: true do |t|
    t.integer  "num_correct",    default: 0
    t.integer  "num_skipped",    default: 0
    t.integer  "num_incorrect",  default: 0
    t.integer  "points",         default: 0
    t.integer  "rank"
    t.boolean  "round_complete", default: true
    t.integer  "round_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "results", ["round_id"], name: "index_results_on_round_id"
  add_index "results", ["user_id"], name: "index_results_on_user_id"

  create_table "rounds", force: true do |t|
    t.integer  "num_participants",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_qo_index",        default: 0
    t.integer  "difficulty_level_id"
  end

  add_index "rounds", ["difficulty_level_id"], name: "index_rounds_on_difficulty_level_id"

  create_table "users", force: true do |t|
    t.string   "player_tag"
    t.string   "password_digest"
    t.integer  "facebook_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "difficulty_level_id"
  end

  add_index "users", ["difficulty_level_id"], name: "index_users_on_difficulty_level_id"

end
