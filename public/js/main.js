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
	$scope.filter = {}

	var isempty = function(obj) {
		for(var i in obj) {return false};
		return true;
	}

	$scope.showclg = false
	$scope.click_clg = function() {
		$scope.showclg ? $scope.showclg = false : $scope.showclg = true
		if($scope.showclg == true){
			$scope.filter["clg"] = true
		} else {
			delete $scope.filter["clg"]
		}
		
	}
	$scope.showtsm = false
	$scope.click_tsm = function() {
		$scope.showtsm ? $scope.showtsm = false : $scope.showtsm = true
		if($scope.showtsm == true){
			$scope.filter["tsm"] = true
			console.log($scope.filter)
		} else {
			delete $scope.filter["tsm"]
		}
		
	}

	$scope.filterall = function(stream) {
		if(isempty($scope.filter)) {
			return true;
		} else {
			console.log($scope.filter[stream.streamer.team])
			return $scope.filter[stream.streamer.team]
		}
	}

}])