describe RenameParams::Macros::Rename, type: :controller do
  context 'when not filtering' do
    let(:default_params) { { controller: 'anonymous', action: 'index' } }
    before { routes.draw { get 'index' => 'anonymous#index' } }

    describe 'when just renaming params' do
      controller(ActionController::Base) do
        rename :username, to: :login

        def index
          head :ok
        end
      end

      it 'renames username to login' do
        get :index, with_params(username: 'aperson')
        expect(controller.params).to eq build_params(default_params.merge(login: 'aperson'))
      end

      context 'if param is not sent' do
        it 'leaves params as they were' do
          get :index
          expect(controller.params).to eq build_params(default_params)
        end
      end
    end

    describe 'when converting values' do
      context 'and using enum converter' do
        controller(ActionController::Base) do
          rename :admin, to: :role, convert: { true: ['admin'], false: [] }

          def index
            head :ok
          end
        end

        it 'renames admin to role and converts value' do
          get :index, with_params(admin: 'true')
          expect(controller.params).to eq build_params(default_params.merge(role: ['admin']))
        end

        context 'if param is not sent' do
          it 'leaves params as they were' do
            get :index
            expect(controller.params).to eq build_params(default_params)
          end
        end

        context 'if param is not included in enum' do
          it 'leaves params as they were' do
            get :index, with_params(admin: 'some_value')
            expect(controller.params).to eq build_params(default_params.merge(role: 'some_value'))
          end
        end
      end

      context 'and using a Proc converter' do
        controller(ActionController::Base) do
          rename :amount_due, to: :amount_due_in_cents, convert: ->(value) { value.to_i * 100 }

          def index
            head :ok
          end
        end

        it 'renames amount_due to amount_due_in_cents and converts value' do
          get :index, with_params(amount_due: 100)
          expect(controller.params).to eq build_params(default_params.merge(amount_due_in_cents: 10000))
        end

        context 'if param is not sent' do
          it 'leaves params as they were' do
            get :index
            expect(controller.params).to eq build_params(default_params)
          end
        end
      end

      context 'and using a method converter' do
        controller(ActionController::Base) do
          rename :amount_due, to: :amount_due_in_cents, convert: :to_cents

          def index
            head :ok
          end

          private

          def to_cents(value)
            value.to_f * 100
          end
        end

        it 'renames amount_due to amount_due_in_cents and converts value' do
          get :index, with_params(amount_due: 100)
          expect(controller.params).to eq build_params(default_params.merge(amount_due_in_cents: 10000))
        end

        context 'if param is not sent' do
          it 'leaves params as they were' do
            get :index
            expect(controller.params).to eq build_params(default_params)
          end
        end
      end

      context 'if param is nested' do
        controller(ActionController::Base) do
          rename :admin, to: :role, namespace: :user, convert: { true: ['admin'], false: [] }

          def index
            head :ok
          end
        end

        it 'renames admin to role and converts value' do
          get :index, with_params(user: { admin: 'true' })
          expect(controller.params).to eq build_params(default_params.merge({ user: { role: ['admin'] } }))
        end
      end
    end

    describe 'when nested params' do
      context 'using only one namespace' do
        controller(ActionController::Base) do
          rename :username, to: :login, namespace: :session

          def index
            head :ok
          end
        end

        it 'renames username to login' do
          get :index, with_params('session' => { 'username' => 'aperson' })
          expect(controller.params).to eq build_params(default_params.merge(session: { login: 'aperson' }))
        end

        context 'if param is not sent' do
          it 'leaves params as they were' do
            get :index, with_params('session' => '')
            expect(controller.params).to eq build_params(default_params.merge(session: ''))
          end
        end
      end

      context 'using more than one nest levels' do
        controller(ActionController::Base) do
          rename :username, to: :login, namespace: [:session, :credentials]

          def index
            head :ok
          end
        end

        it 'renames username to login' do
          get :index, with_params('session' => { 'credentials' => { 'username' => 'aperson' } })
          expect(controller.params).to eq build_params(default_params.merge(session: { credentials: { login: 'aperson' } }))
        end

        context 'if param is not sent' do
          it 'leaves params as they were' do
            get :index, with_params('session' => { 'credentials' => '' })
            expect(controller.params).to eq build_params(default_params.merge(session: { credentials: '' }))
          end
        end

        context 'if namespace is not sent' do
          it 'leaves params as they were' do
            get :index, with_params('session' => '')
            expect(controller.params).to eq build_params(default_params.merge(session: ''))
          end
        end
      end
    end
  end

  context 'when filtering' do
    context 'using only' do
      controller(ActionController::Base) do
        rename :username, to: :login, only: :show

        def index
          head :ok
        end

        def show
          head :ok
        end
      end

      describe 'show' do
        before { routes.draw { get 'show' => 'anonymous#show' } }

        it 'renames username to login' do
          get :show, with_params(username: 'aperson')
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'show', login: 'aperson'))
        end
      end

      describe 'index' do
        before { routes.draw { get 'index' => 'anonymous#index' } }

        it 'keeps username param' do
          get :index, with_params(username: 'aperson')
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'index', username: 'aperson'))
        end
      end
    end

    context 'using except' do
      controller(ActionController::Base) do
        rename :username, to: :login, except: :show

        def index
          head :ok
        end

        def show
          head :ok
        end
      end

      describe 'show' do
        before { routes.draw { get 'show' => 'anonymous#show' } }

        it 'keeps username param' do
          get :show, with_params(username: 'aperson')
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'show', username: 'aperson'))
        end
      end

      describe 'index' do
        before { routes.draw { get 'index' => 'anonymous#index' } }

        it 'renames username to login' do
          get :index, with_params(username: 'aperson')
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'index', login: 'aperson'))
        end
      end
    end
  end

  context 'when using move_to' do
    context 'with :root' do
      controller(ActionController::Base) do
        rename :name, to: :billing_contact_name, namespace: :billing_contact, move_to: :root

        def update
          head :ok
        end
      end

      describe 'move_to' do
        before { routes.draw { get 'update' => 'anonymous#update' } }

        it 'renames billing_contact[:name] to billing_contact_name' do
          put :update, with_params(billing_contact: { name: 'Marcelo' })
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'update', billing_contact: {}, billing_contact_name: 'Marcelo'))
        end
      end
    end

    context 'with existent nested key' do
      controller(ActionController::Base) do
        rename :street, to: :address_street, namespace: [:billing_contact, :address], move_to: :billing_contact

        def update
          head :ok
        end
      end

      describe 'move_to' do
        before { routes.draw { get 'update' => 'anonymous#update' } }

        it 'renames billing_contact[:address][:street] to billing_contact[:street_address]' do
          put :update, with_params(billing_contact: { address: { street: '123 St' } })
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'update', billing_contact: { address: {}, address_street: '123 St' } ))
        end
      end
    end

    context 'with non existent nested key' do
      controller(ActionController::Base) do
        rename :name, to: :name, namespace: :billing_contact, move_to: :contact

        def update
          head :ok
        end
      end

      describe 'move_to' do
        before { routes.draw { get 'update' => 'anonymous#update' } }

        context 'when sending params' do
          it 'renames billing_contact[:name] to contact[:name]' do
            put :update, with_params(billing_contact: { name: 'Marcelo' })
            expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'update', billing_contact: {}, contact: { name: 'Marcelo' }))
          end
        end

        context 'when not sending params' do
          it 'leaves params as they were' do
            put :update
            expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'update'))
          end
        end
      end
    end

    context 'with non existent deep nested key' do
      controller(ActionController::Base) do
        rename :name, to: :name, namespace: :billing_contact, move_to: [:contact, :info]

        def update
          head :ok
        end
      end

      describe 'move_to' do
        before { routes.draw { get 'update' => 'anonymous#update' } }

        it 'renames billing_contact[:name] to contact[:info][:name]' do
          put :update, with_params(billing_contact: { name: 'Marcelo' })
          expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'update', billing_contact: {}, contact: { info: { 'name' =>'Marcelo' } }))
        end
      end
    end

    context 'and converting values' do
      controller(ActionController::Base) do
        rename :admin, to: :role, namespace: :user, convert: { true: ['admin'], false: [] }, move_to: :root

        def index
          head :ok
        end
      end

      it 'renames admin to role and converts value' do
        get :index, with_params(user: { admin: 'true' })
        expect(controller.params).to eq(build_params(controller: 'anonymous', action: 'index', user: {}, role: ['admin']))
      end
    end
  end
end
