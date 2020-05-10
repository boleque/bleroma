defmodule Pleroma do
  use Tesla
  require Logger
  require Poison

  # https://hexdocs.pm/tesla/Tesla.Middleware.FormUrlencoded.html
  plug Tesla.Middleware.FormUrlencoded

  plug Tesla.Middleware.BaseUrl, Application.get_env(:app, :instance_client_id)

  @moduledoc """
  Functions for accessing pleroma
  """

  # doesn't work
  def create_app(base_instance, scopes) do
# curl -X POST \
# 	-F 'client_name=Test Application' \
# 	-F 'redirect_uris=urn:ietf:wg:oauth:2.0:oob' \
# 	-F 'scopes=read write follow push' \
# 	-F 'website=https://myapp.example' \
# 	https://mastodon.example/api/v1/apps

    query_params = [
        client_name:  "bleroma",
        redirect_uris:  "urn:ietf:wg:oauth:2.0:oob",
        scopes: scopes,
        website: "https://bleroma.birdity.club"
    ]

    {:ok, response} = Tesla.post(base_instance <> "/api/v1/apps", query_params)
  end

  # return uri for user to give us authorization code
  # authorization can be used in get_access_token()
  def auth_request_url(scopes) do

    client_id = Application.get_env(:app, :instance_client_id)
    base_instance = Application.get_env(:app, :instance_url)

    query_params = [
        client_id:  client_id,
        response_type:  "code",
        redirect_uri:  "urn:ietf:wg:oauth:2.0:oob",
        scope:  scopes
        # force_login:  force_login
    ]

    base_instance <> "/oauth/authorize?" <> URI.encode_query(query_params)
  end

  def get_access_token(code) do
    base_instance = Application.get_env(:app, :instance_url)
    client_id = Application.get_env(:app, :instance_client_id)
    client_secret = Application.get_env(:app, :instance_client_secret)

    query_params = %{
      "client_id" => client_id,
      "client_secret" => client_secret,
      "redirect_uri" => "urn:ietf:wg:oauth:2.0:oob",
      "grant_type" => "authorization_code",
      "code" => code
      }

    case Pleroma.post(base_instance <> "/oauth/token", query_params) do
      {:ok, response} -> {:ok, Poison.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  def verify_creds(access_token) do
    base_instance = Application.get_env(:app, :instance_url)
    client_id = Application.get_env(:app, :instance_client_id)
    client_secret = Application.get_env(:app, :instance_client_secret)

    headers = [{"Authorization", "Bearer " <> access_token}]

    case Pleroma.get(base_instance <> "/api/v1/apps/verify_credentials", data: "",
          headers: headers) do
      {:ok, response} -> {:ok, Poison.decode!(response.body)}
      {:error, reason} -> {:error, reason}
    end
  end

  def status_post(access_token, status, in_reply_to_id \\ nil, media_ids \\ nil, sensitive \\ false, visibility \\ nil) do

    base_instance = Application.get_env(:app, :instance_url)

    query_params = %{
      status: status
    }

    headers = [{"Authorization", "Bearer " <> access_token}]

    Pleroma.post(base_instance <> "/api/v1/statuses", query_params, headers: headers)
    # Pleroma.post("https://httpbin.org/post", query_params, headers: headers)
  end

end