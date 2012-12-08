require 'spec_helper'

describe CASinoCore::Processor::LoginCredentialAcceptor do
  describe '#process' do
    let(:listener) { Object.new }
    let(:processor) { described_class.new(listener) }

    context 'without a valid login ticket' do
      it 'should call the #invalid_login_ticket method on the listener' do
        listener.should_receive(:invalid_login_ticket).with(no_args)
        processor.process
      end
    end

    context 'with a valid login ticket' do
      let(:login_ticket) { CASinoCore::Model::LoginTicket.create! ticket: "LT-#{Random.rand(10000000)}" }

      context 'with invalid credentials' do
        it 'should call the #invalid_login_credentials method on the listener' do
          listener.should_receive(:invalid_login_credentials).with(no_args)
          processor.process(lt: login_ticket.ticket)
        end
      end

      context 'with valid credentials' do
        let(:login_data) { { lt: login_ticket.ticket, username: 'testuser', password: 'foobar123', service: service } }

        before(:each) do
          listener.stub(:user_logged_in)
        end

        context 'without a service' do
          let(:service) { nil }

          it 'should call the #user_logged_in method on the listener' do
            listener.should_receive(:user_logged_in).with(nil, /^TGC\-/)
            processor.process(lt: login_ticket.ticket, username: 'testuser', password: 'foobar123')
          end

          it 'should have generated a ticket-granting ticket' do
            lambda do
              processor.process(login_data)
            end.should change(CASinoCore::Model::TicketGrantingTicket, :count).by(1)
          end
        end

        context 'with a service' do
          let(:service) { 'https://www.example.com' }

          it 'should call the #user_logged_in method on the listener' do
            listener.should_receive(:user_logged_in).with(/^#{service}\?ticket=ST\-/, /^TGC\-/)
            processor.process(login_data)
          end

          it 'should have generated a service ticket' do
            lambda do
              processor.process(login_data)
            end.should change(CASinoCore::Model::ServiceTicket, :count).by(1)
          end

          it 'should have generated a ticket-granting ticket' do
            lambda do
              processor.process(login_data)
            end.should change(CASinoCore::Model::TicketGrantingTicket, :count).by(1)
          end
        end
      end
    end
  end
end
