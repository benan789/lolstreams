var app = angular.module('LoLStreamsApp', ['ui.router', 'ngResource', 'ngCookies'])

app.run(['$rootScope', '$stateParams', function($rootScope, $stateParams) {
	$rootScope.$on('$stateChangeSuccess',function(event, toState, toParams, fromState, fromParams){
        if($stateParams.name == undefined) {
			$rootScope.showstreamer = false;
		}
    });
	
	$rootScope.activestream = undefined;
	$rootScope.activechat = undefined;
}])

app.config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider){

	$urlRouterProvider.otherwise('/');

	$stateProvider
		.state('home', {
			url: '/'
		})
		.state('stream', {
			url: '/:name',
			controller: function($rootScope, $stateParams, $sce) {
				$rootScope.showstreamer = true;
				$rootScope.activestream = $stateParams.name;
				$rootScope.activechat = $sce.trustAsResourceUrl("http://twitch.tv/chat/embed?channel=" + $stateParams.name + "&amp;popout_chat=true")
			}
		})
}]);

app.factory('Stream', function($resource) {
	return $resource('/streams/:name')
})

app.factory('Favorite', function($resource) {
	return $resource('/favorites')
})

app.factory('User', function($resource) {
	return $resource('/user')
})

app.controller('StreamsCtrl', ['$scope', '$cookies', '$cookieStore', '$sce', '$state', 'Stream', 'Favorite', 'User', '$stateParams', '$http', function($scope, $cookies, $cookieStore, $sce, $state, Stream, Favorite, User, $stateParams, $http) {
	
	var streams = Stream.query(function() {
		$scope.streams = streams
	})

	var favstreams = Favorite.query(function() {
		$scope.favstreams = favstreams
	})

	var user = User.get(function() {
		$scope.user = user
	})

	console.log(user)

	$scope.showteams = false
	$scope.showrank = false

	$scope.showlist = function() {

		$scope.showteams ? $scope.showteams = false : $scope.showteams = true
	}

	$scope.showlist2 = function() {
		$scope.showrank ? $scope.showrank = false : $scope.showrank = true
	}

	$scope.team_filter = {
		'clg': false,
		'tsm': false,
		'dig': false,
		'c9': false,
		'lmq': false		
	}

	$scope.rank_filter = {
		'CHALLENGER': false,
		'MASTER': false,
		'DIAMOND': false,
		'PLATINUM': false,
		'GOLD': false,
		'SILVER': false,
		'BRONZE': false
	}

	$scope.fav_filter = {}
		
	$scope.click_team = function(team) {
		$scope.team_filter[team] ? $scope.team_filter[team] = false : $scope.team_filter[team] = true
	}
		
	$scope.filterteams = function(stream) {
		for (var key in $scope.team_filter) {
			if ($scope.team_filter[key]){
				return $scope.team_filter[stream.streamer.team];
			}	
		}
		return true;
	}

	$scope.click_rank = function(rank) {
		$scope.rank_filter[rank] ? $scope.rank_filter[rank] = false : $scope.rank_filter[rank] = true
	}

	$scope.fav_box = false;
	$scope.click_fav = function(fav) {
		$scope.fav_box ? $scope.fav_box = false : $scope.fav_box = true
		if(fav.length == 0) {
			$scope.fav_box ? $scope.fav_filter['favoritesempty'] = true : $scope.fav_filter['favoritesempty'] = false;
		} else {
			angular.forEach(fav, function(stream, key) {
				$scope.fav_box ? $scope.fav_filter[stream.channel.name] = true : $scope.fav_filter[stream.channel.name] = false;
			})
		}
		console.log($scope.fav_filter)
	}

	$scope.filterrank = function(stream) {
		for (var key in $scope.rank_filter) {
			if ($scope.rank_filter[key]){
				return $scope.rank_filter[stream.rank];
			}	
		}
		return true;
	}

	$scope.filterfav = function(stream) {
		for (var key in $scope.fav_filter) {
			if ($scope.fav_filter[key]){
				return $scope.fav_filter[stream.channel.name];
			}	
		}
		return true;
	}

	$scope.follow = function(stream, user) {
		$http.put("https://api.twitch.tv/kraken/users/" + user.name + "/follows/channels/" + stream.channel.name + "?oauth_token=" + user.user_id)
	}

	if ($stateParams.name) {
		$scope.showstream($stateParams.name);
	}

	$scope.showstream = function(streamer) {
		$state.go("stream", {"name": streamer})
	}

	$scope.closestream = function() {
		$state.go("home")
	}

}])