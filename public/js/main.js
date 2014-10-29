var app = angular.module('LoLStreamsApp', ['ui.router', 'ngResource'])

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
			url: '/',
			controller: 'StreamsCtrl'
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

app.controller('StreamsCtrl', ['$scope', '$sce', '$state', 'Stream', '$stateParams', '$http', function($scope, $sce, $state, Stream, $stateParams, $http) {
	console.log($stateParams)
	var streams = Stream.query(function() {
		if($scope.showclg == true){
			console.log("sdf")
			$scope.streams = $filter('filter')($scope.streams, {team: "clg"})
		} else {
			$scope.streams = streams
		}
	})

	$scope.showteams = false
	$scope.showrank = false

	$scope.showlist = function() {

		$scope.showteams ? $scope.showteams = false : $scope.showteams = true
	}

	$scope.showlist2 = function() {
		$scope.showrank ? $scope.showrank = false : $scope.showrank = true
	}

	$scope.filter = {
		'clg': false,
		'tsm': false,
		'dig': false,
		'c9': false,
		'lmq': false
	}

	$scope.click_team = function(team) {
		$scope.filter[team] ? $scope.filter[team] = false : $scope.filter[team] = true
	}
		
	$scope.filterall = function(stream) {
		for (var key in $scope.filter) {
			if ($scope.filter[key]){
				return $scope.filter[stream.streamer.team];
			}
			if ($scope.filter[key]){
				return $scope.filter[stream.streamer.rank];
			}
		}
		return true;
	}

	if ($stateParams.name) {
		$scope.showstream($stateParams.name);
	}

	$scope.showstream = function(streamer) {
		$state.go("stream", {"name": streamer})
	}

	$scope.closestream = function() {
		$scope.showstreamer = false;
		$state.go("home")
	}

}])