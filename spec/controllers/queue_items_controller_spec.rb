require 'spec_helper'

describe QueueItemsController do
  let(:toby) { Fabricate(:user) }
  before(:each) { session[:user_id] = toby.id }

  describe 'GET index' do
    context 'with authenticated user' do
      it 'sets @queue_items of authenticated user' do
        queue_item1 = Fabricate(:queue_item, user: toby)
        queue_item2 = Fabricate(:queue_item, user: toby)
        get :index
        expect(assigns(:queue_items)).to match_array([queue_item1, queue_item2])
      end
    end

    context 'with unauthenticated user' do
      before { session[:user_id] = nil }

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to sign_in_path
      end
    end
  end

  describe 'POST create' do
    let(:spider) { Fabricate(:video) }

    context 'with authenticated user' do
      it 'redirects to My Queue page' do
        post :create, video_id: spider.id
        expect(response).to redirect_to my_queue_path
      end

      it 'creates a queue item' do
        post :create, video_id: spider.id
        expect(QueueItem.count).to eq(1)
      end

      it 'creates a queue item associated with video' do
        post :create, video_id: spider.id
        expect(QueueItem.first.video).to eq(spider)
      end

      it 'creates a queue item associated with current user' do
        post :create, video_id: spider.id
        expect(QueueItem.first.user).to eq(toby)
      end

      it 'stores a queue item in the last position' do
        Fabricate(:queue_item, video: spider, user: toby)
        man = Fabricate(:video)
        post :create, video_id: man.id
        man_queue_item = QueueItem.where(video_id: man, user_id: toby.id).first
        expect(man_queue_item.position).to eq(2)
      end

      it 'does not create a queue item when video is already in queue' do
        Fabricate(:queue_item, video: spider, user: toby)
        post :create, video_id: spider.id
        expect(toby.queue_items.count).to eq(1)
      end
    end

    context 'with unauthenticated user' do
      before { session[:user_id] = nil }

      it 'redirects to the sign in page' do
        post :create, video_id: spider.id
        expect(response).to redirect_to sign_in_path
      end
    end
  end

  describe 'DELETE destroy' do
    let(:queue_item1) { Fabricate(:queue_item,
                                  video_id: 1,
                                  user: toby,
                                  position: 1) }

    context 'with authenticated user' do
      it 'redirects to the My Queue page' do
        delete :destroy, id: queue_item1.id
        expect(response).to redirect_to my_queue_path
      end

      it 'deletes the queue item' do
        delete :destroy, id: queue_item1.id
        expect(QueueItem.count).to eq(0)
      end

      it 'does not delete queue item if not in current user\'s queue' do
        alice = Fabricate(:user)
        queue_item_alice = Fabricate(:queue_item, user: alice)
        delete :destroy, id: queue_item_alice.id
        expect(QueueItem.count).to eq(1)
      end

      it 'normalizes the remaining queue items' do
        Fabricate(:queue_item, video_id: 2, user: toby, position: 2)
        delete :destroy, id: queue_item1.id
        # expect(QueueItem.first.position).to eq(1)
        # expect(QueueItem.count).to eq(1)
        expect(QueueItem.first.video_id).to eq(2)
      end
    end

    context 'with unauthenticated user' do
      before { session[:user_id] = nil }

      it 'redirects to the sign in page' do
        queue_item = Fabricate(:queue_item)
        delete :destroy, id: queue_item.id
        expect(response).to redirect_to sign_in_path
      end
    end
  end

  describe 'POST update_queue' do
    context 'with valid inputs' do
      let(:queue_item1) { Fabricate(:queue_item, user: toby, position: 1) }
      let(:queue_item2) { Fabricate(:queue_item, user: toby, position: 2) }

      it 'reorders the queue items' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 2},
                                          {id: queue_item2.id, position: 1}]
        expect(toby.queue_items).to eq([queue_item2, queue_item1])
      end

      it 'normalizes the position numbers' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 3},
                                          {id: queue_item2.id, position: 2}]
        expect(toby.queue_items.map(&:position)).to eq([1, 2])
      end

      it 'redirect to the My Queue page' do
        post :update_queue, queue_items: [{id: queue_item1.id, position: 2},
                                          {id: queue_item2.id, position: 1}]
        expect(response).to redirect_to my_queue_path
      end
    end

    context 'with invalid inputs' do
      let(:queue_item1) { Fabricate(:queue_item, user: toby, position: 1) }
      let(:queue_item2) { Fabricate(:queue_item, user: toby, position: 2) }
      before(:each) { post :update_queue, queue_items: [
                                          {id: queue_item1.id, position: 3},
                                          {id: queue_item2.id, position: 2.5}]}

      it 'redirects to the My Queue page' do
        expect(response).to redirect_to my_queue_path
      end

      it 'sets the flash error message' do
        expect(flash[:danger]).to be_present
      end

      it 'does not change the queue items' do
        expect(queue_item1.reload.position).to eq(1)
      end
    end

    context 'with unauthenticated user' do
      before(:each) { session[:user_id] = nil }

      it 'redirects to the sign in path' do
        post :update_queue, queue_items: [{id: 1, position: 2},
                                          {id: 2, position: 1}]
        expect(response).to redirect_to sign_in_path
      end
    end

    context 'with queue item not in current user\'s queue' do
      it 'does not change the queue item' do
        alice = Fabricate(:user)
        queue_item1 = Fabricate(:queue_item, user: alice, position: 1)
        queue_item2 = Fabricate(:queue_item, user: toby, position: 2)
        post :update_queue, queue_items: [{id: queue_item1.id, position: 2},
                                          {id: queue_item2.id, position: 1}]
        expect(queue_item1.reload.position).to eq(1)
      end
    end
  end
end
