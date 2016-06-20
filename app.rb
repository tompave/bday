require "sinatra"
require "json"
require_relative "./lib/person"

CONTENT_JSON = { "Content-Type" => "application/json" }
CONTENT_TEXT = { "Content-Type" => "text/plain" }

RESPONSE_CREATED = [201, CONTENT_JSON, [%Q|{ "done?" : "done!" }|]]
RESPONSE_OK = [200, CONTENT_JSON, [%Q|{ "done?" : "done!" }|]]
RESPONSE_ERROR = [400, CONTENT_JSON, [%Q|{ "error" : "Something went wrong. Odd. DEFINITELY not a 500 though!" }|]]
RESPONSE_UNAUTHORIZED = [403, CONTENT_JSON, [%Q|{ "error" : "you can't do that!" }|]]
RESPONSE_NOT_FOUND = [404, CONTENT_JSON, [%Q|{ "error" : "Not Found" }|]]

HOME_BODY = <<-HOME
Hello,

So, I'll soon celebrate 31 full trips around the Sun, and I'll go out for some drinks
on Sat 2nd July 2016, at 20:00 (ish).

I've tentatively reserved at The Roebuck (https://goo.gl/maps/2hvhJwygbAr).
I'll let you know if that changes.

You can RSVP with:

  curl --data "name=Tom&coming=yes&secret=whatever" http://birthday.pavese.me/people

Parameters:
  name: your name, can be anything;
  coming: whether you're coming (e.g. "yes", "no", "maybe", "true");
  secret: to authenticate future requests.


You can update your "coming" status by re-submitting with the same "name" and "secret".

To delete your RSVP (for example because you want to change your name):

  curl -X DELETE http://birthday.pavese.me/people/yourname/yoursecret


To check who's coming visit http://birthday.pavese.me/people

If you don't know what to do with these instructions, you can send me an email
at tommaso[at]pavese[dot]me and I'll update your RSVP for you.

If you find a bug, PRs are welcome! (https://github.com/tompave/bday)
(please don't DDOS me)


I hope to see you there!

Cheers,
Tom

HOME

get "/people" do
  [200, CONTENT_JSON, JSON.dump(Person.all)]
end


post "/people" do
  if person = find_person
    if person.can_update?(params[:secret])
      person.coming = params[:coming]
      person.save
    else
      return RESPONSE_UNAUTHORIZED
    end
  else
    ok = Person.rsvp(name: params[:name], coming: params[:coming], secret: params[:secret])
    return RESPONSE_ERROR unless ok
  end
  RESPONSE_CREATED
end

delete "/people/:name/:secret" do
  if person = find_person
    if person.can_update?(params[:secret])
      person.delete
      RESPONSE_OK
    else
      RESPONSE_UNAUTHORIZED
    end
  else
    RESPONSE_NOT_FOUND
  end
end

get "/" do
  [200, CONTENT_TEXT, [HOME_BODY]]
end

get "/*" do
  RESPONSE_NOT_FOUND
end

post "/*" do
  RESPONSE_NOT_FOUND
end

delete "/*" do
  RESPONSE_NOT_FOUND
end


def find_person
  Person.find(params[:name])
end
