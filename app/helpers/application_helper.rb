module ApplicationHelper
  # pagy_url_for and friends for the custom pagination partials. Pagy ships
  # its own pt-BR locale (gem locales/pt-BR.yml), but the overtime pager is
  # a custom partial that uses the app's Rails i18n keys instead.
  include Pagy::Frontend

  # Shared Tailwind classes (Phase 6 sweep): one source of truth for the
  # form input and primary-button styling used across the auth and CRUD views.
  def input_classes
    "mt-1 block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm shadow-sm transition-colors duration-150 focus:border-red-500 focus:outline-none focus:ring-2 focus:ring-red-200"
  end

  def primary_button_classes
    "w-full cursor-pointer rounded-lg bg-red-600 px-4 py-3 text-sm font-semibold text-white transition-colors duration-150 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-200"
  end

  # Sets the per-page <title> (rendered via content_for(:title) in the layout)
  # and doubles as the Open Graph/Twitter title. Usage: page_title t(".title").
  def page_title(title)
    content_for(:title, title)
  end
end
