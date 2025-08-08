defmodule Barrage.EmbeddedWordlists do
  @moduledoc """
  Embedded wordlist functionality for self-contained binary distribution.
  """

  # Embed all wordlist files at compile time
  @external_resource "wordlists/common.txt"
  @external_resource "wordlists/cms-drupal.txt"
  @external_resource "wordlists/cms-joomla.txt"
  @external_resource "wordlists/django-python.txt"
  @external_resource "wordlists/dotnet-core.txt"
  @external_resource "wordlists/ecommerce-platforms.txt"
  @external_resource "wordlists/elixir-phoenix.txt"
  @external_resource "wordlists/go-frameworks.txt"
  @external_resource "wordlists/java-spring.txt"
  @external_resource "wordlists/nodejs-express.txt"
  @external_resource "wordlists/php-laravel.txt"
  @external_resource "wordlists/react-next.txt"
  @external_resource "wordlists/ruby-rails.txt"
  @external_resource "wordlists/vue-nuxt.txt"
  @external_resource "wordlists/wordpress.txt"

  @common_wordlist File.read!("wordlists/common.txt")
  @cms_drupal File.read!("wordlists/cms-drupal.txt")
  @cms_joomla File.read!("wordlists/cms-joomla.txt")
  @django_python File.read!("wordlists/django-python.txt")
  @dotnet_core File.read!("wordlists/dotnet-core.txt")
  @ecommerce_platforms File.read!("wordlists/ecommerce-platforms.txt")
  @elixir_phoenix File.read!("wordlists/elixir-phoenix.txt")
  @go_frameworks File.read!("wordlists/go-frameworks.txt")
  @java_spring File.read!("wordlists/java-spring.txt")
  @nodejs_express File.read!("wordlists/nodejs-express.txt")
  @php_laravel File.read!("wordlists/php-laravel.txt")
  @react_next File.read!("wordlists/react-next.txt")
  @ruby_rails File.read!("wordlists/ruby-rails.txt")
  @vue_nuxt File.read!("wordlists/vue-nuxt.txt")
  @wordpress File.read!("wordlists/wordpress.txt")

  def get_wordlist("common.txt"), do: @common_wordlist
  def get_wordlist("cms-drupal.txt"), do: @cms_drupal
  def get_wordlist("cms-joomla.txt"), do: @cms_joomla
  def get_wordlist("django-python.txt"), do: @django_python
  def get_wordlist("dotnet-core.txt"), do: @dotnet_core
  def get_wordlist("ecommerce-platforms.txt"), do: @ecommerce_platforms
  def get_wordlist("elixir-phoenix.txt"), do: @elixir_phoenix
  def get_wordlist("go-frameworks.txt"), do: @go_frameworks
  def get_wordlist("java-spring.txt"), do: @java_spring
  def get_wordlist("nodejs-express.txt"), do: @nodejs_express
  def get_wordlist("php-laravel.txt"), do: @php_laravel
  def get_wordlist("react-next.txt"), do: @react_next
  def get_wordlist("ruby-rails.txt"), do: @ruby_rails
  def get_wordlist("vue-nuxt.txt"), do: @vue_nuxt
  def get_wordlist("wordpress.txt"), do: @wordpress

  def get_wordlist("wordlists/" <> filename), do: get_wordlist(filename)
  def get_wordlist(_), do: @common_wordlist

  def list_available_wordlists do
    [
      "common.txt",
      "cms-drupal.txt",
      "cms-joomla.txt",
      "django-python.txt",
      "dotnet-core.txt",
      "ecommerce-platforms.txt",
      "elixir-phoenix.txt",
      "go-frameworks.txt",
      "java-spring.txt",
      "nodejs-express.txt",
      "php-laravel.txt",
      "react-next.txt",
      "ruby-rails.txt",
      "vue-nuxt.txt",
      "wordpress.txt"
    ]
  end
end
