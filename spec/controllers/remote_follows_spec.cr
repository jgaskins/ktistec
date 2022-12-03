require "../../src/controllers/remote_follows"

require "../spec_helper/factory"
require "../spec_helper/controller"
require "../spec_helper/network"

Spectator.describe RemoteFollowsController do
  setup_spec

  let(actor) { register.actor }

  describe "GET /actors/:username/remote-follow" do
    context "when accepting HTML" do
      let(headers) { HTTP::Headers{"Accept" => "text/html"} }

      it "returns 404 if not found" do
        get "/actors/missing/remote-follow", headers
        expect(response.status_code).to eq(404)
      end

      it "succeeds" do
        get "/actors/#{actor.username}/remote-follow", headers
        expect(response.status_code).to eq(200)
      end

      it "renders a form" do
        get "/actors/#{actor.username}/remote-follow", headers
        expect(XML.parse_html(response.body).xpath_nodes("//form[.//input[@name='account']]")).not_to be_empty
      end
    end

    context "when accepting JSON" do
      let(headers) { HTTP::Headers{"Accept" => "application/json"} }

      it "returns 404 if not found" do
        get "/actors/missing/remote-follow", headers
        expect(response.status_code).to eq(404)
      end

      it "succeeds" do
        get "/actors/#{actor.username}/remote-follow", headers
        expect(response.status_code).to eq(200)
      end

      it "returns a template" do
        get "/actors/#{actor.username}/remote-follow", headers
        expect(JSON.parse(response.body).dig?("account")).not_to be_nil
      end
    end
  end

  describe "POST /actors/:username/remote-follow" do
    context "when posting form data" do
      let(headers) { HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded", "Accept" => "text/html"} }

      it "returns 404 if not found" do
        post "/actors/missing/remote-follow", headers, ""
        expect(response.status_code).to eq(404)
      end

      it "renders an error if address is missing" do
        post "/actors/#{actor.username}/remote-follow", headers, ""
        expect(XML.parse_html(response.body).xpath_nodes("//form/div[contains(@class,'error message')]/p").first).
          to match(/The address must not be blank/)
      end

      it "renders an error if address is blank" do
        post "/actors/#{actor.username}/remote-follow", headers, "account="
        expect(XML.parse_html(response.body).xpath_nodes("//form/div[contains(@class,'error message')]/p").first).
          to match(/The address must not be blank/)
      end

      it "retains the address if address is invalid" do
        post "/actors/#{actor.username}/remote-follow", headers, "account=xyz"
        expect(XML.parse_html(response.body).xpath_nodes("//form//input[@name='account']/@value").first).
          to eq("xyz")
      end

      it "redirects if succesful" do
        post "/actors/#{actor.username}/remote-follow", headers, "account=foobar%40remote.com"
        expect(response.status_code).to eq(302)
      end

      it "returns the remote location if successful" do
        post "/actors/#{actor.username}/remote-follow", headers, "account=foobar%40remote.com"
        expect(response.headers["Location"]?).
          to eq("https://remote.com/actors/foobar/authorize-follow?uri=#{URI.encode_path(actor.iri)}")
      end

      it "returns the remote location if successful" do
        post "/actors/#{actor.username}/remote-follow", headers, "account=%40foobar%40remote.com"
        expect(response.headers["Location"]?).
          to eq("https://remote.com/actors/foobar/authorize-follow?uri=#{URI.encode_path(actor.iri)}")
      end
    end

    context "when posting JSON data" do
      let(headers) { HTTP::Headers{"Content-Type" => "application/json"} }

      it "returns 404 if not found" do
        post "/actors/missing/remote-follow", headers, "{}"
        expect(response.status_code).to eq(404)
      end

      it "returns an error message if address is missing" do
        post "/actors/#{actor.username}/remote-follow", headers, "{}"
        expect(JSON.parse(response.body).dig?("msg")).
          to match(/The address must not be blank/)
      end

      it "returns an error message if address is blank" do
        post "/actors/#{actor.username}/remote-follow", headers, {account: ""}.to_json
        expect(JSON.parse(response.body).dig?("msg")).
          to match(/The address must not be blank/)
      end

      it "retains the address if address is invalid" do
        post "/actors/#{actor.username}/remote-follow", headers, {account: "xyz"}.to_json
        expect(JSON.parse(response.body).dig?("account")).
          to eq("xyz")
      end

      it "succeeds" do
        post "/actors/#{actor.username}/remote-follow", headers, {account: "foobar@remote.com"}.to_json
        expect(response.status_code).to eq(200)
      end

      it "returns the remote location if successful" do
        post "/actors/#{actor.username}/remote-follow", headers, {account: "foobar@remote.com"}.to_json
        expect(JSON.parse(response.body).dig?("location")).
          to eq("https://remote.com/actors/foobar/authorize-follow?uri=#{URI.encode_path(actor.iri)}")
      end

      it "returns the remote location if successful" do
        post "/actors/#{actor.username}/remote-follow", headers, {account: "@foobar@remote.com"}.to_json
        expect(JSON.parse(response.body).dig?("location")).
          to eq("https://remote.com/actors/foobar/authorize-follow?uri=#{URI.encode_path(actor.iri)}")
      end
    end
  end

  describe "GET /actors/:username/authorize-follow" do
    sign_in(as: actor.username)

    let_build(:actor, named: :other, iri: "https://remote/actors/foobar")

    before_each { HTTP::Client.actors << other }

    context "when accepting HTML" do
      let(headers) { HTTP::Headers{"Accept" => "text/html"} }

      it "returns 404 if not found" do
        get "/actors/missing/authorize-follow", headers
        expect(response.status_code).to eq(404)
      end

      it "returns 403 if different account" do
        get "/actors/#{register.actor.username}/authorize-follow", headers
        expect(response.status_code).to eq(403)
      end

      it "returns 400 if the uri is missing" do
        get "/actors/#{actor.username}/authorize-follow", headers
        expect(response.status_code).to eq(400)
      end

      it "returns 400 if the uri can't be dereferenced" do
        get "/actors/#{actor.username}/authorize-follow?uri=https://remote/returns-404", headers
        expect(response.status_code).to eq(400)
      end

      it "succeeds" do
        get "/actors/#{actor.username}/authorize-follow?uri=https%3A%2F%2Fremote%2Factors%2Ffoobar", headers
        expect(response.status_code).to eq(200)
      end

      it "renders a follow page" do
        get "/actors/#{actor.username}/authorize-follow?uri=https%3A%2F%2Fremote%2Factors%2Ffoobar", headers
        expect(XML.parse_html(response.body).xpath_nodes("//form[.//input[@value='Follow']][.//input[@value='https://remote/actors/foobar']]")).
          not_to be_empty
      end
    end

    context "when accepting JSON" do
      let(headers) { HTTP::Headers{"Accept" => "application/json"} }

      it "returns 404 if not found" do
        get "/actors/missing/authorize-follow", headers
        expect(response.status_code).to eq(404)
      end

      it "returns 403 if different account" do
        get "/actors/#{register.actor.username}/authorize-follow", headers
        expect(response.status_code).to eq(403)
      end

      it "returns 400 if the uri is missing" do
        get "/actors/#{actor.username}/authorize-follow", headers
        expect(response.status_code).to eq(400)
      end

      it "returns 400 if the uri can't be dereferenced" do
        get "/actors/#{actor.username}/authorize-follow?uri=https://remote/returns-404", headers
        expect(response.status_code).to eq(400)
      end

      it "succeeds" do
        get "/actors/#{actor.username}/authorize-follow?uri=https%3A%2F%2Fremote%2Factors%2Ffoobar", headers
        expect(response.status_code).to eq(200)
      end

      it "returns the actor" do
        get "/actors/#{actor.username}/authorize-follow?uri=https%3A%2F%2Fremote%2Factors%2Ffoobar", headers
        expect(JSON.parse(response.body)["id"]?).
          to eq("https://remote/actors/foobar")
      end
    end
  end
end
