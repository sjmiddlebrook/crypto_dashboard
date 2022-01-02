defmodule CryptoDashboardWeb.LayoutView do
  use CryptoDashboardWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_path_class(%{path_info: path_info} = _conn, path, is_mobile \\ false) do
    current_path = Path.join(["/" | path_info])
    active_path_class(current_path === path, is_mobile)
  end

  def active_path_class(true = _is_match, false = _is_mobile) do
    "active-nav-path"
  end

  def active_path_class(false = _is_match, false = _is_mobile) do
    "nav-path"
  end

  def active_path_class(true = _is_match, true = _is_mobile) do
    "active-mobile-nav-path"
  end

  def active_path_class(false = _is_match, true = _is_mobile) do
    "mobile-nav-path"
  end
end
