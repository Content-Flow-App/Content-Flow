class FetchSubstackSourceJob < ApplicationJob
  queue_as :default

  def perform(substack_source_id)
    source = SubstackSource.find_by(id: substack_source_id)
    return unless source

    SubstackFetchService.call(source)
  end
end
