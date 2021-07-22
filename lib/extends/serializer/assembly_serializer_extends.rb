# frozen_string_literal: true

module AssemblySerializerExtends
  # Public: Initializes the serializer with a assembly.
  def initialize(assembly, private_scope = false)
    @assembly = assembly
    @private_scope = private_scope
  end
end

Decidim::Assemblies::AssemblySerializer.class_eval do
  prepend(AssemblySerializerExtends)
end
