var app = angular.module('LoLStreamsApp', ['ui.router', 'ngResource'])

app.config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider){

	$urlRouterProvider.otherwise('/');

	$stateProvider
		.state('home', {
			url: '/'
		})
		.state('stream', {
			url: '/:name',
			templateUrl: '/views/show.html'
		})
}]);

app.factory('Stream', function($resource) {
	return $resource('/streams/:name')
})

app.controller('StreamsCtrl', ['$scope', '$filter', 'Stream', '$stateParams', '$http', function($scope, $filter, Stream, $stateParams, $http) {
	var streams = Stream.query(function() {
		if($scope.showclg == true){
			console.log("sdf")
			$scope.streams = $filter('filter')($scope.streams, {team: "clg"})
		} else {
			$scope.streams = streams
		}
	})

	var stream = Stream.get({name: 'wingsofdeath'}, function() {
		$scope.stream = stream
		console.log($scope.stream)
	})

	$scope.showteams = false
	$scope.showrank = false
	$scope.showlist = function() {

		$scope.showteams ? $scope.showteams = false : $scope.showteams = true
	}

	$scope.showlist2 = function() {
		$scope.showrank ? $scope.showrank = false : $scope.showrank = true
	}

	$scope.showclg = false
	$scope.click_clg = function() {
		$scope.showclg ? $scope.showclg = false : $scope.showclg = true
		if($scope.showclg == true){
			return stream.streamer.team == "tsm"
		} else {
			$scope.streams = streams
		}
	}



}])