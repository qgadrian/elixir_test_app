# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :test_app,
  ecto_repos: [TestApp.Repo]

# Configures the endpoint
config :test_app, TestApp.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YDpvkHddxkLosrWciMv4C1RRKxee7JKJH1rYyIDxa9zQ/X5TdetPQDGE8XieZXuD",
  render_errors: [view: TestApp.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TestApp.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Authentication token library config
config :guardian, Guardian,
  allowed_algos: ["ES512"],
  issuer: "TestApp",
  ttl: { 3, :days },
  verify_issuer: true,
  secret_key: %{
                  "crv" => "P-521",
                  "d" => "axDuTtGavPjnhlfnYAwkHa4qyfz2fdseppXEzmKpQyY0xd3bGpYLEF4ognDpRJm5IRaM31Id2NfEtDFw4iTbDSE",
                  "kty" => "EC",
                  "x" => "AL0H8OvP5NuboUoj8Pb3zpBcDyEJN907wMxrCy7H2062i3IRPF5NQ546jIJU3uQX5KN2QB_Cq6R_SUqyVZSNpIfC",
                  "y" => "ALdxLuo6oKLoQ-xLSkShv_TA0di97I9V92sg1MKFava5hKGST1EKiVQnZMrN3HO8LtLT78SNTgwJSQHAXIUaA-lV"
                },
  serializer: TestApp.GuardianSerializer