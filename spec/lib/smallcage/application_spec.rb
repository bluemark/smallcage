require 'spec_helper.rb'
require 'smallcage'

describe SmallCage::Application do

  def capture_result
    status = nil
    result = nil
    tmpout = StringIO.new
    tmperr = StringIO.new
    original_out, $stdout = $stdout, tmpout
    original_err, $stderr = $stderr, tmperr
    begin
      result = yield
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = original_out
      $stderr = original_err
    end

    return {
      :exit => status,
      :result => result,
      :stdout => tmpout.string,
      :stderr => tmperr.string
    }
  end

  subject { SmallCage::Application.new }

  it 'should parse update command' do
    options = subject.parse_options(['update', '.'])
    options.should eq(:path => '.', :command => :update, :quiet => false, :fast => false)
  end

  it 'should parse up command' do
    options = subject.parse_options(['up', '.'])
    options.should eq(:path => '.', :command => :update, :quiet => false, :fast => false)
  end

  it 'should parse clean command' do
    options = subject.parse_options(['clean', '.'])
    options.should eq(:path => '.', :command => :clean, :quiet => false)
  end

  it 'should parse server command' do
    options = subject.parse_options(['server', '.'])
    options.should eq(:path => '.', :command => :server, :quiet => false, :port => 8080) # num

    options = subject.parse_options(['sv', '.', '8080'])
    options.should eq(:path => '.', :command => :server, :quiet => false, :port => 8080) # string
  end

  it 'should accept only number port' do
    result = capture_result { subject.parse_options(['server', '.', 'pot']) }
    result[:exit].should eq 1
    result[:stdout].should be_empty
    result[:stderr].should eq "illegal port number: pot\n"
  end

  it 'should not accept port 0' do
    result = capture_result { subject.parse_options(['server', '.', '0']) }
    result[:exit].should eq 1
    result[:stdout].should be_empty
    result[:stderr].should eq "illegal port number: 0\n"
  end

  it 'should parse auto command' do
    options = subject.parse_options(['auto', '.'])
    options.should eq(
                      :path => '.',
                      :command => :auto,
                      :port => nil,
                      :bell => false,
                      :fast => false,
                      :quiet => false
                      )

    options = subject.parse_options(['au', '.', '8080'])
    options.should eq(
                      :path => '.',
                      :command => :auto,
                      :port => 8080,
                      :bell => false,
                      :fast => false,
                      :quiet => false
                      )
  end

  it 'should parse import command' do
    options = subject.parse_options(['import', 'base', '.'])
    options.should eq(:command => :import, :from => 'base', :to => '.', :quiet => false)

    options = subject.parse_options(['import'])
    options.should eq(:command => :import, :from => 'default', :to => '.', :quiet => false)
  end

  it 'should parse export command' do
    options = subject.parse_options(['export', '.', 'path'])
    options.should eq(:command => :export, :path => '.',  :out => 'path', :quiet => false)

    options = subject.parse_options(['export'])
    options.should eq(:command => :export, :path => '.',  :out => nil, :quiet => false)
  end

  it 'should parse uri command' do
    options = subject.parse_options(['uri', './path/to/target'])
    options.should eq(:command => :uri, :path => './path/to/target', :quiet => false)

    options = subject.parse_options(['uri'])
    options.should eq(:command => :uri, :path => '.', :quiet => false)
  end

  it 'should parse manifest command' do
    options = subject.parse_options(['manifest', './path/to/target'])
    options.should eq(:command => :manifest, :path => './path/to/target', :quiet => false)

    options = subject.parse_options(['manifest'])
    options.should eq( :command => :manifest, :path => '.', :quiet => false )
  end

  it 'should exit 1 if command is empty' do
    result = capture_result { subject.parse_options([]) }
    result[:exit].should eq 1
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it 'should show help' do
    result = capture_result { subject.parse_options(['help']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it 'should show help if the arguments include --help' do
    result = capture_result { subject.parse_options(['--help', 'update']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it 'should show subcommand help' do
    result = capture_result { subject.parse_options(['help', 'update']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\AUsage: smc update \[path\]/
    result[:stderr].should be_empty
  end

  it 'should exit if the command is unknown' do
    result = capture_result { subject.parse_options(['xxxx']) }
    result[:exit].should eq 1
    result[:stdout].should be_empty
    result[:stderr].should eq "no such subcommand: xxxx\n"
  end

  it 'should show version' do
    result = capture_result { subject.parse_options(['--version', 'update']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it 'should exit when subcommand is empty' do
    result = capture_result { subject.parse_options(['', '--version']) }
    result[:exit].should eq 1
    result[:stdout].should =~ /\AUsage:/
    result[:stdout].should =~ /^Subcommands are:/
    result[:stderr].should be_empty
  end

  it 'should ignore subcommand with --version option' do
    result = capture_result { subject.parse_options(['help', '--version']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it 'should ignore subcommand with -v option' do
    result = capture_result { subject.parse_options(['help', '-v']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\ASmallCage \d+\.\d+\.\d+ - /
    result[:stderr].should be_empty
  end

  it 'should ignore subcommand with --help option' do
    result = capture_result { subject.parse_options(['update', '--help']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\AUsage: smc update \[path\] \[options\]/
    result[:stderr].should be_empty
  end

  it 'should ignore subcommand with -h option' do
    result = capture_result { subject.parse_options(['update', '-h']) }
    result[:exit].should eq 0
    result[:stdout].should =~ /\AUsage: smc update \[path\] \[options\]/
    result[:stderr].should be_empty
  end

  it 'should exit with unknown main option --QQQ' do
    result = capture_result { subject.parse_options(['--QQQ']) }
    result[:exit].should eq 1
    result[:stdout].should be_empty
    result[:stderr].should eq "invalid option: --QQQ\n"
  end

  it 'should exit with unknown sub option --QQQ' do
    result = capture_result { subject.parse_options(['update', '--QQQ']) }
    result[:exit].should eq 1
    result[:stdout].should be_empty
    result[:stderr].should eq "invalid option: --QQQ\n"
  end

  it 'should accept auto command --bell option' do
    result = capture_result { subject.parse_options(['auto', '--bell']) }
    result[:exit].should be_nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should eq(
      :command => :auto,
      :port => nil,
      :path => '.',
      :bell => true,
      :fast => false,
      :quiet => false
    )
  end

  it 'should set bell option false as default' do
    result = capture_result { subject.parse_options(['auto']) }
    result[:exit].should be_nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should eq(
      :command => :auto,
      :port => nil,
      :path => '.',
      :bell => false,
      :fast => false,
      :quiet => false
    )
  end

  it 'should accept --quiet option' do
    result = capture_result { subject.parse_options(['--quiet', 'update']) }
    result[:exit].should be_nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should eq(
      :command => :update,
      :path => '.',
      :fast => false,
      :quiet => true
    )
  end

  it 'should accept --quiet option after subcommand' do
    result = capture_result { subject.parse_options(['update', '--quiet']) }
    result[:exit].should be_nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should eq(
      :command => :update,
      :path => '.',
      :fast => false,
      :quiet => true
    )
  end

  it 'should accept --quiet option before and after subcommand' do
    opts = %w{--quiet auto --quiet path --bell 80}
    result = capture_result { subject.parse_options(opts) }
    result[:exit].should be_nil
    result[:stdout].should be_empty
    result[:stderr].should be_empty
    result[:result].should eq(
      :command => :auto,
      :path => 'path',
      :port => 80,
      :bell => true,
      :fast => false,
      :quiet => true
    )
  end

end
