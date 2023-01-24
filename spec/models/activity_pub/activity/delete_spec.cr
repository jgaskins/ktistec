require "../../../../src/models/activity_pub/activity/delete"

require "../../../spec_helper/base"
require "../../../spec_helper/factory"

Spectator.describe ActivityPub::Activity::Delete do
  setup_spec

  subject { described_class.new(iri: "http://test.test/#{random_string}") }

  describe "#actor" do
    it "returns an actor or actor subclass" do
      expect(typeof(subject.actor)).to eq({{(ActivityPub::Actor.all_subclasses << ActivityPub::Actor).join("|").id}})
    end
  end

  describe "#object" do
    it "returns an actor, object or one of their subclasses" do
      expect(typeof(subject.object)).to eq({{((ActivityPub::Actor.all_subclasses + ActivityPub::Object.all_subclasses) << ActivityPub::Actor << ActivityPub::Object).join("|").id}})
    end
  end

  context "validations" do
    let_build(:actor)
    let_build(:actor, named: :other)
    let_build(:object, attributed_to: other)

    context "when the object is an object" do
      let(activity) { subject.assign(actor: other, object: object) }

      it "fails if the actor is not the object's creator" do
        activity.actor = actor
        expect(activity.valid?).to be_false
        expect(activity.errors["activity"]).to contain("the actor must be the object's actor")
      end

      it "passes validation if the object has been deleted" do
        activity.actor = actor
        activity.object.deleted_at = Time.utc
        expect(activity.valid?).to be_true
        expect(activity.errors).to be_empty
      end

      it "passes validation" do
        expect(activity.valid?).to be_true
        expect(activity.errors).to be_empty
      end
    end

    context "when the object is an actor" do
      let(activity) { subject.assign(actor: other, object: other) }

      it "fails if the actors do not match" do
        activity.actor = actor
        expect(activity.valid?).to be_false
        expect(activity.errors["activity"]).to contain("the actors must match")
      end

      it "passes validation if the object has been deleted" do
        activity.actor = actor
        activity.object.deleted_at = Time.utc
        expect(activity.valid?).to be_true
        expect(activity.errors).to be_empty
      end
      it "passes validation" do
        expect(activity.valid?).to be_true
        expect(activity.errors).to be_empty
      end
    end
  end

  describe "#to_json_ld" do
    let_build(:delete)

    subject { JSON.parse(delete.to_json_ld) }

    it "doesn't recursively serialize the actor" do
      expect(subject.dig("actor").as_s?).to be_truthy
    end

    it "doesn't recursively serialize the object" do
      expect(subject.dig("object").as_s?).to be_truthy
    end
  end
end
