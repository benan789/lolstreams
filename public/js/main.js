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

app.controller('StreamsCtrl', ['$scope', 'Stream', '$stateParams', '$http', function($scope, Stream, $stateParams, $http) {
	var streams = Stream.query(function() {
		$scope.streams = streams
	})

	

	var stream = Stream.get({name: 'wingsofdeath'}, function() {
		$scope.stream = stream
		console.log($scope.stream)
	})

}])