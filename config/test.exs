import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :web_ui, WebUI.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "9qBuNlK623tCbJ3HMwvXMGa1ENG/RVnEwgWiOGNUP695VB9GslLoDy25V01qxkbR",
  server: false
