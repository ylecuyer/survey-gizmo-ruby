# Survey Gizmo (ruby)

Integrate with the [Alchemer API](https://apihelp.alchemer.com/help) using an ActiveModel style interface.

Currently supports Alchemer API **v4** (default) and **v3**.

## Version History

[See the change log.](CHANGELOG.md)

## Installation

```ruby
gem 'survey-gizmo-ruby'
```

## Configuration

The configuration is thread safe.
When a new thread is created, the last configuration set through `SurveyGizmo.configure` or `SurveyGizmo.configuration=` will be used.
When `SurveyGizmo.reset!` is called, only the current thread configuration will be reset.

```ruby
require 'survey-gizmo-ruby'

# Configure your credentials
SurveyGizmo.configure do |config|
  config.api_token = 'still_tippin_woodgraingrip'
  config.api_token_secret = 'it_takes_grindin_to_be_a_king'

  # Optional - Defaults to v4, but you can probably set to v3 safely if you suspect a bug in v4
  config.api_version = 'v4'

  # Optional - Set if you need to hit a different region (e.g. the .eu domain)
  config.region = :eu

  # Optional - Defaults to 50, maximum 500. Setting too high may cause SurveyGizmo to start throwing timeouts.
  config.results_per_page = 100

  # Optional - Defaults to 300 seconds
  config.timeout_seconds = 600

  # Optional - Defaults to English. If the survey has just one translation in languages different than English, with this option methods always return the proper locale.
  config.locale = 'Italian'

  # Optional - Configure arguments to the Retriable gem directly that will be merged into the defaults
  config.retriable_params = { tries: 30, max_elapsed_time: 3600 }
end
```

Check the [Retriable](https://github.com/kamui/retriable) documentation for how to configure the `retriable_params` hash.
The default is to retry 3 times, with 60 seconds before the first retry and a slow exponential backoff after that.

`api_token` and `api_token_secret` can be read from environment variables, in which case you would set them like this:

```bash
$ export SURVEYGIZMO_API_TOKEN=till_tippin_woodgraingrip
$ export SURVEYGIZMO_API_TOKEN_SECRET=it_takes_grindin_to_be_a_king
$ bundle exec ruby whatever
```

And then your ruby code just has to make sure to call

```ruby
SurveyGizmo.configure
````

once at some point to load the tokens out of the `ENV` and into the configuration.

## Usage

### Retrieving Data

`SurveyGizmo::API::Klass.first` returns a single instance of the resource.

`SurveyGizmo::API::Klass.all` returns an `Enumerator` you can use to loop through your results/questions/surveys etc.  It will actually iterate through ALL your results (pagination will be handled for you) if you pass `all_pages: true`.

Because `.all` returns an `Enumerator`, you have to call `.each` or `.to_a` or some other enumerable method to trigger actual API data retrieval.
```ruby
SurveyGizmo::API::Survey.all(all_pages: true)      # => #<Enumerator: #<Enumerator::Generator>:each>
SurveyGizmo::API::Survey.all(all_pages: true).to_a # => [Survey, Survey, Survey, ...]
```

### Examples

```ruby
# Iterate over your all surveys directly with the iterator
SurveyGizmo::API::Survey.all(all_pages: true).each { |survey| do_something_with(survey) }
# Iterate over the 1st page of your surveys
SurveyGizmo::API::Survey.all(page: 1).each { |survey| do_something_with(survey) }

# Retrieve the survey with id: 12345
survey = SurveyGizmo::API::Survey.first(id: 12345)
survey.title # => "My Title"
survey.pages # => [page1, page2,...]
survey.number_of_completed_responses # => 355
survey.server_has_new_results_since?(Time.now.utc - 2.days) # => true
survey.team_names # => ['Development', 'Test']
survey.belongs_to?('Development') # => true

# Retrieve all questions for all pages of this survey
questions = survey.questions
# Strip out instruction, urlredirect, logic, media, and other non question "questions"
questions = survey.actual_questions

# Create a question for your survey.  The returned object will be given an :id parameter by SG.
question = SurveyGizmo::API::Question.create(survey_id: survey.id, title: 'Do u ruby?', type: 'checkbox')
# Update a question
question.title = "Do u <3 Ruby?"
question.save
# Destroy a question
question.destroy

# Iterate over all your Responses
survey.responses.each { |response| do_something_with(response) }
# Use filters to limit results - this example will iterate over page 3 of completed, non test data
# SurveyResponses submitted within the past 3 days for contact 999. The example `filters` array
# demonstrates how to use some of the gem's built in filters/generators as well as how to construct
# an ad hoc filter hash.
# See: http://apihelp.surveygizmo.com/help/article/link/filters for more info on filters
filters = [
  SurveyGizmo::API::Response::NO_TEST_DATA,
  SurveyGizmo::API::Response::ONLY_COMPLETED,
  SurveyGizmo::API::Response.submitted_since_filter(Time.now - 72.hours),
  {
    field: 'contact_id',
    operator: '=',
    value: 999
  }
]
survey.responses(page: 3, filters: filters).each { |response| do_stuff_with(response) }

# Parse the answer hash into a more usable format.
# Answers with keys but empty values will not be returned.
# "Other" text for some questions is parsed to Answer#other_text; all other answers to Answer#answer_text
# Custom table question answers have the question_pipe string parsed out to Answer#question_pipe.
# See http://apihelp.surveygizmo.com/help/article/link/surveyresponse-per-question for more info on answers
response.parsed_answers => # [#<SurveyGizmo::API::Answer @survey_id=12345, @question_id=1, @option_id=2, @answer_text='text'>]

# Retrieve all answers from all responses to all surveys, write rows to your database
SurveyGizmo::API::Survey.all(all_pages: true).each do |survey|
  survey.responses.each do |response|
    response.parsed_answers.each do |answer|
      MyLocalSurveyGizmoResponseModel.create(answer.to_hash)
    end
  end
end
```

## Debugging

The GIZMO_DEBUG environment variable will trigger full printouts of SurveyGizmo's HTTP responses and variable introspection for almost everything.

```bash
cd /my/app
export GIZMO_DEBUG=true
bundle exec rails whatever
```

## Adding API Objects

Currently, the following API objects are included in the gem: `Survey`, `Question`, `Option`, `Page`, `Response`, `EmailMessage`, `Campaign`, `Contact`, `AccountTeams`. If you want to use something that isn't included you can easily write a class that handles it. Here's an example of the how to do so:

```ruby
class SomeObject
  # the base where most of the methods for handling the API are stored
  include SurveyGizmo::Resource

  # the attributes the object should respond to
  attribute :id,          Integer
  attribute :title,       String
  attribute :status,      String
  attribute :type,        String
  attribute :created_on,  DateTime

  # define the paths used to retrieve/set info
  # if the routing is such that :get, :update, and :delete only append /:id to the main route, do this
  @route = '/something'
  # but if the class needs special routing, specify each method route with a hash:
  @route = {
    get: '/something/:id',
    update: '/something/weird/:id',
    create: '/something',
    delete: '/something/delete/:id'
  }
end
```

The [Virtus](https://github.com/solnic/virtus) gem is included to handle the attributes, so please check their documentation as well.

# Contributing to survey-gizmo-ruby

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Take a gander at the github issues beforehand
* Fork the project
* Start a feature/bugfix branch and hack away
* Make sure to add specs for it!!!!
* Submit a pull request
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Desirable/Missing Features

* Better specs with VCR/Webmock
* OAuth authentication
* Better foreign language support
* There are several API objects that are available and not included in this gem.  AccountTeams, for instance, has some skeleton code but is untested.

# Copyright

Copyright (c) 2012 RipTheJacker. See LICENSE.txt for
further details.
