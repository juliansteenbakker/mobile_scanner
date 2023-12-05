package dev.steenbakker.mobile_scanner

class NoCamera : Exception()
class AlreadyStarted : Exception()
class AlreadyStopped : Exception()
class CameraError : Exception()
class ZoomWhenStopped : Exception()
class ZoomNotInRange : Exception()