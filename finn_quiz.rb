#!/usr/bin/env ruby
# frozen_string_literal: true
# finn_quiz.rb
# version 1.0


require "yaml"
require "time"
require "optparse"

# -----------------------------
# Utility
# -----------------------------

def say(msg = "")
  puts msg
end

def prompt(msg)
  print msg
  STDOUT.flush
  STDIN.gets&.chomp
end

def normalize_basic(s)
  s.to_s.strip.downcase
end

def normalize_lenient_umlauts(s)
  normalize_basic(s).tr("äö", "ao")
end

def pct(part, total)
  return 0.0 if total.to_i <= 0
  (part.to_f / total.to_f) * 100.0
end

# -----------------------------
# YAML Loading
# -----------------------------

def load_words(path)
  data = YAML.load_file(path)

  words =
    if data.is_a?(Array)
      data
    elsif data.is_a?(Hash)
      data.map do |en, v|
        v ||= {}
        { "en" => en, "fi" => v["fi"] || v[:fi], "phon" => v["phon"] || v[:phon] }
      end
    else
      raise "Unsupported YAML structure."
    end

  words.map do |w|
    en = w["en"] || w[:en]
    fi = w["fi"] || w[:fi]
    phon = w["phon"] || w[:phon]
    raise "Invalid word entry: #{w.inspect}" if en.to_s.empty? || fi.to_s.empty?
    { en: en.to_s.strip, fi: fi.to_s.strip, phon: phon.to_s.strip }
  end
end

def choose_words(words, count)
  return words.shuffle if count.nil? || count == "all"

  n = Integer(count)
  words.shuffle.take([n, words.length].min)
end

# -----------------------------
# Matching Logic
# -----------------------------

def match_answer(user, expected, lenient:)
  user_n = normalize_basic(user)
  exp_n  = normalize_basic(expected)

  return [:exact, true] if user_n == exp_n
  return [:no, false] unless lenient

  user_l = normalize_lenient_umlauts(user)
  exp_l  = normalize_lenient_umlauts(expected)

  return [:umlaut_lenient, true] if user_l == exp_l
  [:no, false]
end


def pick_distractors(pool, correct_fi)
  candidates = pool.map { |w| w[:fi] }.uniq - [correct_fi]
  raise "Not enough distractors." if candidates.size < 2
  candidates.sample(2)
end

# -----------------------------
# Quiz Engine
# -----------------------------

def run_quiz(selected, pool:, lenient:, match_game:)
  stats = { total: selected.length, correct_1: 0, correct_2: 0, failed: 0 }
  missed = []

  say
  say "Finnish Quiz — #{stats[:total]} word(s) (mode: #{match_game ? 'match-game' : 'typing'})"
  say "-" * 50

  selected.each_with_index do |w, idx|
    say
    say "[#{idx + 1}/#{stats[:total]}] English: #{w[:en]}"
    answer_ok = false

    1.upto(2) do |attempt|
if match_game
  distractors = pick_distractors(pool, w[:fi])
  options = ([w[:fi]] + distractors).shuffle

  say "Options:"
  options.each { |opt| say "  - #{opt}" }

  input = prompt("Type the Finnish word: ")
  kind, ok = match_answer(input, w[:fi], lenient: lenient)

  if ok
    stats[:"correct_#{attempt}"] += 1
    if kind == :umlaut_lenient
      say "✅ Hyvä! Muista: ä ja ö ovat tärkeitä 😉"
    else
      say "✅ Oikein!"
    end
    say "   (phonetic: #{w[:phon]})" unless w[:phon].empty?
    answer_ok = true
    break
  else
    say "\n❌ Yritä uudelleen.\n" if attempt < 2
  end
      else
        input = prompt("Finnish: ")
        kind, ok = match_answer(input, w[:fi], lenient: lenient)

        if ok
          stats[:"correct_#{attempt}"] += 1
          if kind == :umlaut_lenient
            say "✅ Hyvä! Muista: ä ja ö ovat tärkeitä 😉"
          else
            say "✅ Oikein!"
          end
          say "   (phonetic: #{w[:phon]})" unless w[:phon].empty?
          answer_ok = true
          break
        else
          say "Yritä uudelleen." if attempt < 2
        end
      end
    end

    unless answer_ok
      stats[:failed] += 1
      say "❌ Oikea sana: #{w[:fi]}#{w[:phon].empty? ? '' : " (#{w[:phon]})"}"
      missed << w
    end
  end

  [stats, missed]
end

# -----------------------------
# Output
# -----------------------------

def write_missed_file(input_path, stats, missed, lenient:, match_game:)
  base = File.basename(input_path, File.extname(input_path))
  filename = "#{base}_missed_#{Time.now.strftime('%Y%m%d_%H%M%S')}.yaml"

  payload = {
    meta: {
      generated_at: Time.now.iso8601,
      source_file: File.expand_path(input_path),
      lenient_umlauts: lenient,
      match_game: match_game
    },
    stats: stats,
    missed: missed
  }

  File.write(filename, YAML.dump(payload))
  filename
end

# -----------------------------
# Main
# -----------------------------

options = {
  lenient: false,
  match_game: false,
  count: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby finn_quiz.rb <yaml_file> [count|all] [options]"

  opts.on("--lenient-umlauts", "Allow a for ä and o for ö") do
    options[:lenient] = true
  end

  opts.on("--match-game", "Enable multiple choice mode") do
    options[:match_game] = true
  end
end

parser.parse!

yaml_path = ARGV.shift or abort("Missing YAML file.")
options[:count] = ARGV.shift

words = load_words(yaml_path)
selected = choose_words(words, options[:count])

stats, missed = run_quiz(
  selected,
  pool: words,
  lenient: options[:lenient],
  match_game: options[:match_game]
)

say
say "-" * 50
say "Results"
say "Total: #{stats[:total]}"
say "Correct 1st: #{stats[:correct_1]} (#{pct(stats[:correct_1], stats[:total]).round(1)}%)"
say "Correct 2nd: #{stats[:correct_2]} (#{pct(stats[:correct_2], stats[:total]).round(1)}%)"
say "Failed: #{stats[:failed]} (#{pct(stats[:failed], stats[:total]).round(1)}%)"

if missed.any?
  outfile = write_missed_file(
    yaml_path,
    stats,
    missed,
    lenient: options[:lenient],
    match_game: options[:match_game]
  )

  say
  say "Missed words saved to: #{outfile}"
else
  say
  say "😊 Ei virheitä — hienoa työtä!"
end

