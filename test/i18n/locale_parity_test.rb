require "test_helper"

# The app owns exactly two locale files. pt-BR is the UI locale and :en is the
# pinned fallback (config/application.rb), so any key that exists in only one
# of them renders "translation missing" the moment the fallback kicks in --
# which is exactly what happened with `date.formats.short_date`, missing from
# en while every export calls `I18n.l(date, format: :short_date)`.
#
# Scope: the two files under config/locales only. Stock Devise translations
# ship with the devise-i18n gem (see AGENTS.md) and are not compared here.
class LocaleParityTest < ActiveSupport::TestCase
  LOCALE_FILES = {
    "en" => Rails.root.join("config/locales/en.yml"),
    "pt-BR" => Rails.root.join("config/locales/pt-BR.yml")
  }.freeze

  # CLDR plural categories. Languages do not share a plural rule set -- pt-BR
  # may legitimately need `many:` where English only has `one:`/`other:` -- so
  # the trailing category is collapsed to a `*` placeholder before comparing.
  # Parity therefore means "both files pluralize the same key", not "both files
  # use the same categories".
  PLURAL_CATEGORIES = /\.(zero|one|two|few|many|other)\z/

  # [ dotted key, value ] pairs, with the top-level locale segment dropped.
  def translations(locale)
    root = YAML.load_file(LOCALE_FILES.fetch(locale), aliases: true).fetch(locale)
    flatten_translations(root)
  end

  def flatten_translations(node, prefix = [])
    return [ [ prefix.join("."), node ] ] unless node.is_a?(Hash)

    node.flat_map { |key, value| flatten_translations(value, prefix + [ key.to_s ]) }
  end

  def translation_keys(locale)
    translations(locale).map { |key, _value| key.sub(PLURAL_CATEGORIES, ".*") }.to_set
  end

  test "en.yml and pt-BR.yml define the same keys" do
    english = translation_keys("en")
    brazilian = translation_keys("pt-BR")

    assert_equal english, brazilian, <<~DIFF
      config/locales/en.yml and config/locales/pt-BR.yml have drifted apart.
        missing from pt-BR.yml: #{(english - brazilian).sort.join(', ').presence || '(none)'}
        missing from en.yml:    #{(brazilian - english).sort.join(', ').presence || '(none)'}
    DIFF
  end

  test "no locale key is left blank" do
    LOCALE_FILES.each_key do |locale|
      blank = translations(locale).reject { |_key, value| value.present? }.map(&:first)

      assert_empty blank, "#{locale}.yml has blank values: #{blank.sort.join(', ')}"
    end
  end
end
