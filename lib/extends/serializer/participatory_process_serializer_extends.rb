# frozen_string_literal: true

module ParticipatoryProcessSerializerExtends
  # Public: Initializes the serializer with a participatory_process.
  def initialize(participatory_process, private_scope = false)
    @participatory_process = participatory_process
    @private_scope = private_scope
  end
end

Decidim::ParticipatoryProcesses::ParticipatoryProcessSerializer.class_eval do
  prepend(ParticipatoryProcessSerializerExtends)
end
