class ApplicationGroupsController < ApplicationController
  def index
    @application_groups = ApplicationGroup.page(params[:page]).per(15)
    @application_groups = ApplicationGroup.all_with_multiple_applicants.page(params[:page]).per(15)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @employers }
    end
  end

  def show
    @application_group = ApplicationGroup.find(params[:id])
    @primary_applicant = @application_group.primary_applicant
  end

  def new
    @application_group = ApplicationGroup.new
    build_nested_models
    @person = Person.new
  end

  def create
    @application_group = ApplicationGroup.new(params[:application_group])
    @person = Person.new(params[:person])

    respond_to do |format|
      if @application_group.save
        format.html { redirect_to @application_group, notice: 'Application Group was successfully created.' }
        format.json { render json: @application_group, status: :created, location: @application_group }
      else
        format.html { render action: "new" }
        format.json { render json: @application_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @edit_form = EditApplicationGroupForm.new(params)
  end

  def update
    @application_group = ApplicationGroup.find(params[:id])
    people_to_remove.each { |p| @application_group.people.delete(p) }
    @application_group.save
  end

  def applicants
    @application_group = ApplicationGroup.find(params[:id])
    @applicants = @application_group.active_applicants
  end

  def link_employee
    @application_group = ApplicationGroup.find(params[:id])
  end

  def challenge_identity
    @application_group = ApplicationGroup.find(params[:id])
  end

private
  def people_to_remove
    ppl_hash = params[:edit_application_group_form].fetch(:people_attributes) { {} }

    ids = []
    ppl_hash.each_pair do |index, person|
      ids << person[:person_id] if(person[:remove_selected] == "1")
    end
    @application_group.people.select { |p| ids.include?(p._id.to_s) }
  end

  def build_nested_models
    @applicant = @application_group.applicants.build(primary_applicant: true) if @application_group.applicants.empty?
    @household = @application_group.households.build if @application_group.households.empty?
  end

end
