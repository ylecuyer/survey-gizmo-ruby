# Survey Gizmo (ruby)

[![Build Status](https://travis-ci.org/jarthod/survey-gizmo-ruby.svg?branch=master)](https://travis-ci.org/jarthod/survey-gizmo-ruby)

Integrate with the [Survey Gizmo API](http://apisurveygizmo.helpgizmo.com/help) using an ActiveModel style interface.

Currently supports SurveyGizmo API **v4** (default) and **v3**.

## Versions

### Major Changes in 5.x

* **BREAKING CHANGE**: `.all` returns an `Enumerator`, not an `Array`. This will break your code if you are using the return value of `.all` without iterating over it.
* **BREAKING CHANGE**: `SurveyCampaign` has been renamed `Campaign` to be in line with the other model names.
* FEATURE: `.all` will automatically paginate responses for you with the `:all_pages` option. There are also some built in methods like `Survey#responses` that will auto paginate.
* FEATURE: Built in retries. 1 retry with a 60 second backoff is the default but can be configured.
* FEATURE: `Response#parsed_answers` returns an array of `Answers` (new class) that are sane, stable Ruby objects instead of the sort of wild and wooly way SurveyGizmo has chosen to represent survey responses.

### Major Changes in 4.x

* **BREAKING CHANGE**: There is no more error tracking.  If the API gives an error or bad response, an exception will be raised.
* **BREAKING CHANGE**: There is no more ```copy``` method

### Major Changes in 3.x

* **BREAKING CHANGE**: Configuration is completely different
* Important Change: Defaults to using the v4 SurveyGizmo API endpoint to take advantage of various API bug fixes (notably team ownership is broken in v3)

### Old versions

[Version 2.0.1 for the v3 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v2.0.1)

[Version 1.0.5 for the v2 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v1.0.5)

[Version 0.7.0 for the v1 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v0.7.0)

## Installation

```ruby
gem 'survey-gizmo-ruby'
```

## Configuration

```ruby
require 'survey-gizmo-ruby'

# Configure your credentials
SurveyGizmo.configure do |config|
  config.user = 'still_tippin@woodgraingrip.com'
  config.password = 'it_takes_grindin_to_be_a_king'

  # Optional - Defaults to v4, but you can probably set to v3 safely if you suspect a bug in v4
  config.api_version = 'v4'

  # Optional - Set if you need to hit a different base URL (e.g. the .eu domain)
  config.api_url = 'https://restapi.surveygizmo.eu'

  # Optional - Defaults to 50, maximum 500. Setting too high may cause SurveyGizmo to start throwing timeouts.
  config.results_per_page = 100
end
```

### Retries

The [Pester](https://github.com/lumoslabs/pester) gem is used to manage retry strategies.  By default it will be configured to handle 1 retry with a 60 second timeout upon encountering basic net timeouts and rate limit errors, which is enough for most people's needs.

If, however, you want to specify more retries, a longer backoff, new classes to retry on, or otherwise get fancy with the retry strategy, you can configured Pester directly.  SurveyGizmo API calls are executed in Pester's `survey_gizmo_ruby` environment, so anything you configure there will apply to all your requests.

```ruby
# For example, to change the retry interval, max attempts, or exception classes to be retried:
Pester.configure do |config|
  # Retry 10 times
  config.environments[:survey_gizmo_ruby][:max_attempts] = 10
  # Backoff for 2 minutes
  config.environments[:survey_gizmo_ruby][:delay_interval] = 120
  # Retry different exception classes
  config.environments[:survey_gizmo_ruby][:retry_error_classes] = [MyExceptionClass, MyOtherExceptionClass]
end

# To set Pester to retry on ALL exception classes, do this (use with caution! Can include exceptions Rails likes to throw on SIGHUP)
Pester.configure do |config|
  config.environments[:survey_gizmo_ruby][:retry_error_classes] = nil
end
```

## Usage

### Retrieving Data

`SurveyGizmo::API::Klass.first` returns a single instance of the resource.

`SurveyGizmo::API::Klass.all` returns an `Enumerator` you can use to loop through your results/questions/surveys etc.  It will actually iterate through ALL your results (pagination will be handled for you) if you pass `all_pages: true`.

Because `.all` returns an `Enumerator`, you have to call `.to_a` or some other enumerable method to trigger actual API data retrieval.
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
question = SurveyGizmo::API::Question.create(survey_id: survey.id, title: 'Do you like ruby?', type: 'checkbox')
# Update a question
question.title = "Do you LOVE Ruby?"
question.save
# Destroy a question
question.destroy

# Iterate over all your Responses
survey.responses.each { |response| do_something_with(response) }
# Use filters to limit results - this example will iterate over page 3 of completed, non test data
# SurveyResponses submitted within the past 3 days for contact 999. It demonstrates how to use some of the gem's
# built in filters/generators as well as how to construct a filter.
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
    delete: /something/delete/:id'
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
