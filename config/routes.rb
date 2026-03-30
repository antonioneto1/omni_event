OmniEvent::Engine.routes.draw do
  post 'receiver/:token', to: 'receiver#create', as: :receiver
end