require 'prawn'

class Notice

  attr_accessor :from, :to, :subject, :template, :notice, :mkt_kind, :file_name

  def initialize(recipient, args = {})
    @template = args[:template]
    @notice = args[:notice]
    @email_notice = args[:email_notice] || true
    @pdf_notice = args[:pdf_notice] || true
    # @mailer = args[:mailer] || ApplicationMailer
    @file_name = "notice.pdf"
    @envelope = "envelope.pdf"
  end

  def html
    ApplicationController.new.render_to_string({ 
      :template => @template,
      :layout => 'pdf_notice_layout',
      :locals => { notice: @notice }
    })
  end

  def pdf
    WickedPdf.new.pdf_from_string(
      self.html,
      margin:  {  
        top: 15,
        bottom: 40,
        left: 22,
        right: 22 
      },
      page_size: 'Letter',
      formats: :html, 
      encoding: 'utf8',
      footer: { 
        content: ApplicationController.new.render_to_string( { template: "notices/ivl/footer.html.erb", layout: false })
      }
    )
  end

  def generate_envelope
    envelope = Notices::Envelope.new 
    envelope.fill_envelope(@notice)
    envelope.render_file(Rails.root.join('pdfs', @envelope))
  end

  # def deliver
  #   send_email_notice if @email_notice
  #   send_pdf_notice if @paper_notice
  # end

  # def send_email_notice
  #   @mailer.notice_email(self).deliver_now
  # end

  def save_pdf
    File.open(Rails.root.join('pdfs', @file_name), 'wb') do |file|
      file << self.pdf
    end
  end

  def save_html
    File.open(Rails.root.join('pdfs','notice.html'), 'wb') do |file|
      file << self.html
    end
  end

  def join_pdfs(pdfs)
    Prawn::Document.generate("result.pdf", {:page_size => 'LETTER', :skip_page_creation => true}) do |pdf|
      pdfs.each do |pdf_file|
        if File.exists?(pdf_file)
          pdf_temp_nb_pages = Prawn::Document.new(:template => pdf_file).page_count

          (1..pdf_temp_nb_pages).each do |i|
            pdf.start_new_page(:template => pdf_file, :template_page => i)
          end

          if pdfs.index(pdf_file) == 1 && ((pdf_temp_nb_pages % 2) == 1)
            (1..1).each do |i|
              pdf.start_new_page(:template => Rails.root.join('lib/pdf_pages', 'blank.pdf'), :template_page => i)
            end
          end
        end
      end
    end
  end
end

module Notices
  class Envelope < Generators::Reports::PdfReport

    def initialize
      template = Rails.root.join('lib/pdf_pages', 'ivl_envelope.pdf')

      super({:template => template, :margin => [30, 55]})
      font_size 11
      
      @margin = [30, 70]     
    end

    def fill_envelope(notice)
      x_pos = mm2pt(21.83) - @margin[0]
      y_pos = 790.86 - mm2pt(57.15) - 65

      bounding_box([x_pos, y_pos], :width => 300) do
        fill_recipient_contact(notice)
      end

      x_pos = mm2pt(6.15)
      y_pos = 57

      bounding_box([x_pos, y_pos], :width => 300) do
        text "MPI_IVLR1"
      end
    end

    def fill_recipient_contact(notice)
      text notice.primary_fullname
      text notice.primary_address.street_1
      text notice.primary_address.street_2 unless notice.primary_address.street_2.blank?
      text "#{notice.primary_address.city}, #{notice.primary_address.state} #{notice.primary_address.zip}"      
    end
  end
end

