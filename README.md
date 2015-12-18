# Survey Gizmo (ruby)

Integrate with the [Survey Gizmo API](http://apisurveygizmo.helpgizmo.com/help) using an ActiveModel style interface.

Currently supports SurveyGizmo API **v4** (default) and **v3**.

## Versions

### Major Changes in 4.x

* BREAKING CHANGE: There is no more error tracking.  If the API gives an error or bad response, an exception will be raised.
* BREAKING CHANGE: There is no more ```copy``` method

### Major Changes in 3.x

* BREAKING CHANGE: Configuration is completely different
* Important Change: Defaults to using the v4 SurveyGizmo API endpoint to take advantage of various API bug fixes (notably team ownership is broken in v3)

### Old versions

[Version 2.0.1 for the v3 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v2.0.1)

[Version 1.0.5 for the v2 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v1.0.5)

[Version 0.7.0 for the v1 API is here](https://github.com/RipTheJacker/survey-gizmo-ruby/releases/tag/v0.7.0)

## Installation

```ruby
gem 'survey-gizmo-ruby'
```

## Basic Usage

```ruby
require 'survey-gizmo-ruby'

# Configure your credentials
SurveyGizmo.configure do |config|
  config.user = 'still_tippin@woodgraingrip.com'
  config.password = 'it_takes_grindin_to_be_a_king'

  # Optional - Defaults to v4, but you can probably set to v3 safely if you suspect a bug in v4
  config.api_version = 'v4'

  # Optional - Defaults to 50, maximum 500. Setting too high may cause SurveyGizmo to start throwing timeouts.
  config.results_per_page = 100
end

# Retrieve the first page of your surveys
surveys = SurveyGizmo::API::Survey.all
# Retrieve ALL your surveys (handle pagination for you)
surveys = SurveyGizmo::API::Survey.all(all_pages: true)

# Retrieve the survey with id: 12345
survey = SurveyGizmo::API::Survey.first(id: 12345)
survey.title # => "My Title"
survey.pages # => [page1, page2,...]
survey.number_of_completed_responses # => 355
survey.server_has_new_results_since?(Time.now.utc - 2.days) # => true
survey.team_names # => ['Development', 'Test']
survey.belongs_to?('Development') # => true

# Retrieving Questions for a given survey.  Note that page_id is a required parameter.
questions = SurveyGizmo::API::Question.all(survey_id: survey.id, page_id: 1)
# Or just retrieve all questions for all pages of this survey
questions = survey.questions

# Create a question for your survey.  The returned object will be given an :id parameter by SG.
question = SurveyGizmo::API::Question.create(survey_id: survey.id, title: 'Do you like ruby?', type: 'checkbox')
# Update a question
question.title = "Do you LOVE Ruby?"
question.save
# Destroy a question
question.destroy

# Retrieve 2nd page of SurveyResponses for a given survey.
responses = SurveyGizmo::API::Response.all(survey_id: 12345, page: 2)
# Retrieve all responses for a given survey.
responses = SurveyGizmo::API::Response.all(all_pages: true, survey_id: 12345)
# Retrieving page 3 of completed, non test data SurveyResponses submitted within the past 3 days
# for contact id 999. This example shows you how to use some of the gem's built in filters and
# filter generators as well as how to construct your own raw filter.
# See: http://apihelp.surveygizmo.com/help/article/link/filters for more info on filters
responses = SurveyGizmo::API::Response.all(
  survey_id: 12345,
  page: 3,
  filters: [
    SurveyGizmo::API::Response::NO_TEST_DATA,
    SurveyGizmo::API::Response::ONLY_COMPLETED,
    SurveyGizmo::API::Response.submitted_since_filter(Time.now - 72.hours),
    {
      field: 'contact_id',
      operator: '=',
      value: 999
    }
  ]
)
```

## On API Timeouts

API timeouts are a regular occurrence with the SurveyGizmo API.  At Lumos Labs we use our own [Pester gem](https://github.com/lumoslabs/pester) to manage retry strategies.  It might work for you.

## Debugging

The GIZMO_DEBUG environment variable will trigger full printouts of SurveyGizmo's HTTP responses and variable introspection for almost everything.

```bash
cd /my/app
export GIZMO_DEBUG=true
bundle exec rails whatever
```

## Adding API Objects

Currently, the following API objects are included in the gem: `Survey`, `Question`, `Option`, `Page`, `Response`, `EmailMessage`, `SurveyCampaign`, `Contact`, `AccountTeams`. If you want to use something that isn't included you can easily write a class that handles it. Here's an example of the how to do so:

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

  # defing the paths used to retrieve/set info
  route '/something/:id', via: [:get, :update, :delete]
  route '/something',     via: :create

  # this must be defined with the params that would be included in any route related
  # to an instance of SomeObject
  def to_param_options
    { id: self.id }
  end
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

* Better foreign language support
* Use Faraday instead of Httparty (partied too hard)
* Better specs with VCR/Webmock would be nice.
* There are several API objects that are available and not included in this gem.  AccountTeams, for instance, has some skeleton code but is untested.
* OAuth authentication ability.

# Copyright

Copyright (c) 2012 RipTheJacker. See LICENSE.txt for
further details.

