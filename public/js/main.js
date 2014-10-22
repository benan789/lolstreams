var app = angular.module('lolstreams', ['ui.router', 'ngResource'])

app.config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider){

	$urlRouterProvider.otherwise('/');

	$stateProvider
		.state('home', {
			url: '/',
			template: '<h1>asdfads</h1>'
		});
}]);

app.factory('Streams', function($resource) {
	return $resource('/streams/:name')
})

app.controller('index', ['$scope', 'Streams', function($scope, Streams) {
	var streams = Streams.query(function() {
		$scope.streams = streams
	})
}])