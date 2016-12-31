require 'spec_helper'

describe Griddler::Sendgrid::Adapter do
  it 'registers itself with griddler' do
    Griddler.adapter_registry[:sendgrid].should eq Griddler::Sendgrid::Adapter
  end
end

describe Griddler::Sendgrid::Adapter, '.normalize_params' do
  it_should_behave_like 'Griddler adapter',
    :sendgrid,
    {
      text: 'hi',
      to: 'Hello World <hi@example.com>',
      cc: 'emily@example.com',
      from: 'There <there@example.com>',
    }

  it 'changes attachments to an array of files' do
    params = default_params.merge(
      attachments: '2',
      attachment1: upload_1,
      attachment2: upload_2,
     'attachment-info' => <<-eojson
        {
          "attachment2": {
            "filename": "photo2.jpg",
            "name": "photo2.jpg",
            "type": "image/jpeg"
          },
          "attachment1": {
            "filename": "photo1.jpg",
            "name": "photo1.jpg",
            "type": "image/jpeg",
            "content-id": "5866e4a943fd8_43f946d853108373ab@4ae2c7be-dbe3-46b7-9d15-0a69e63689b2.mail\"
          }
        }
      eojson
    )

    normalized_params = normalize_params(params)
    normalized_params[:attachments].should eq [upload_1, upload_2]
    normalized_params.should_not have_key(:attachment1)
    normalized_params.should_not have_key(:attachment2)
    normalized_params.should_not have_key(:attachment_info)
  end

  it "uses sendgrid attachment info for filename" do
    params = default_params.merge(
      attachments: "2",
      attachment1: upload_1,
      attachment2: upload_2,
      "attachment-info" => <<-eojson
        {
          "attachment2": {
            "filename": "sendgrid-filename2.jpg",
            "name": "photo2.jpg",
            "type": "image/jpeg"
          },
          "attachment1": {
            "filename": "sendgrid-filename1.jpg",
            "name": "photo1.jpg",
            "type": "image/jpeg",
            "content-id": "5866e4a943fd8_43f946d853108373ab@4ae2c7be-dbe3-46b7-9d15-0a69e63689b2.mail\"
          }
        }
      eojson
    )

    attachments = normalize_params(params)[:attachments]

    attachments.first.original_filename.should eq "sendgrid-filename1.jpg"
    attachments.second.original_filename.should eq "sendgrid-filename2.jpg"
    print attachments.inspect
  end

  it "only included attachments" do
    params = default_params.merge(
      attachments: "2",
      attachment1: upload_1,
      attachment2: upload_2,
      "attachment-info" => <<-eojson
        {
          "attachment2": {
            "filename": "sendgrid-filename2.jpg",
            "name": "photo2.jpg",
            "type": "image/jpeg"
          },
          "attachment1": {
            "filename": "sendgrid-filename1.jpg",
            "name": "photo1.jpg",
            "type": "image/jpeg",
            "content-id": "5866e4a943fd8_43f946d853108373ab@4ae2c7be-dbe3-46b7-9d15-0a69e63689b2.mail\"
          }
        }
      eojson
    )

    normalized_params = normalize_params(params)
    normalized_params[:included_attachments].size.should eq 1
    normalized_params[:included_attachments].first.original_filename.should eq "sendgrid-filename2.jpg"
  end

  it "only embedded attachments" do
    params = default_params.merge(
      attachments: "2",
      attachment1: upload_1,
      attachment2: upload_2,
      "attachment-info" => <<-eojson
        {
          "attachment2": {
            "filename": "sendgrid-filename2.jpg",
            "name": "photo2.jpg",
            "type": "image/jpeg"
          },
          "attachment1": {
            "filename": "sendgrid-filename1.jpg",
            "name": "photo1.jpg",
            "type": "image/jpeg",
            "content-id": "5866e4a943fd8_43f946d853108373ab@4ae2c7be-dbe3-46b7-9d15-0a69e63689b2.mail\"
          }
        }
      eojson
    )

    normalized_params = normalize_params(params)
    normalized_params[:embedded_attachments].size.should eq 1
    normalized_params[:embedded_attachments].first.original_filename.should eq "sendgrid-filename1.jpg"
  end

  it 'has no attachments' do
    params = default_params.merge(attachments: '0')

    normalized_params = normalize_params(params)
    normalized_params[:attachments].should be_empty
  end

  it 'splits to into an array' do
    normalized_params = normalize_params(default_params)

    normalized_params[:to].should eq ['"Mr Fugushima at Fugu, Inc" <hi@example.com>', 'Foo bar <foo@example.com>']
  end

  it 'wraps cc in an array' do
    normalized_params = normalize_params(default_params)

    normalized_params[:cc].should eq [default_params[:cc]]
  end

  it 'returns an array even if cc is empty' do
    params = default_params.merge(cc: nil)
    normalized_params = normalize_params(params)

    normalized_params[:cc].should eq []
  end

  it 'returns an array even if bcc is an empty string' do
    params = default_params.merge(envelope: '')
    normalized_params = normalize_params(params)

    normalized_params[:bcc].should eq []
  end

  it 'wraps bcc in an array' do
    normalized_params = normalize_params(default_params)

    normalized_params[:bcc].should eq ["johny@example.com"]
  end

  it 'returns an array even if bcc is empty' do
    params = default_params.merge(envelope: nil)
    normalized_params = normalize_params(params)

    normalized_params[:bcc].should eq []
  end

  it 'returns an empty array when the envelope to is the same as the base to' do
    params = default_params.merge(envelope: "{\"to\":[\"hi@example.com\"]}")
    normalized_params = normalize_params(params)

    normalized_params[:bcc].should eq []
  end

  def default_params
    {
      text: 'hi',
      to: '"Mr Fugushima at Fugu, Inc" <hi@example.com>, Foo bar <foo@example.com>',
      cc: 'cc@example.com',
      from: 'there@example.com',
      envelope: "{\"to\":[\"johny@example.com\"], \"from\": [\"there@example.com\"]}",
    }
  end
end
