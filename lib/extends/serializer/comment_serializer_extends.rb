# frozen_string_literal: true

module CommentSerializerExtends
  def serialize
    {
      t_column_name(:id) => resource.id,
      t_column_name(:created_at) => resource.created_at,
      t_column_name(:body) => resource.body,
      t_column_name(:author, ".author") => {
        t_column_name(:id, ".author") => resource.author.id,
        t_column_name(:name, ".author") => resource.author.name,
        t_column_name(:birth_date, ".author") => key_from_registration_metadata(resource.author, :birth_date).to_s,
        t_column_name(:age_scope, ".author") => age_scope(key_from_registration_metadata(resource.author, :birth_date).to_s),
        t_column_name(:gender, ".author") => key_from_registration_metadata(resource.author, :gender),
        t_column_name(:city_work_area, ".author") => key_from_registration_metadata(resource.author, :city_work_area),
        t_column_name(:city_residential_area, ".author") => key_from_registration_metadata(resource.author, :city_residential_area),
        t_column_name(:statutory_representative_email, ".author") => key_from_registration_metadata(resource.author, :statutory_representative_email)
      },
      t_column_name(:alignment) => resource.alignment,
      t_column_name(:depth) => resource.depth,
      t_column_name(:user_group, ".user_group") => {
        t_column_name(:id, ".user_group") => resource.user_group.try(:id),
        t_column_name(:name, ".user_group") => resource.user_group.try(:name) || empty_translatable
      },
      t_column_name(:commentable_id) => resource.decidim_commentable_id,
      t_column_name(:commentable_type) => resource.decidim_commentable_type,
      t_column_name(:root_commentable_url) => root_commentable_url
    }
  end

  private

  def i18n_scope
    "decidim.comments.exports.column_name.comments"
  end
end

Decidim::Comments::CommentSerializer.class_eval do
  prepend(CommentSerializerExtends)
end
