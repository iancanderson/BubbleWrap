# Provides a nice DSL for interacting with the standard CMMotionManager from
# CoreMotion
#
module BubbleWrap
  module Motion
    module Error
    end

    class Generic

      def initialize(manager)
        @manager = manager
      end

      def every(time=nil, options={} &block)
        raise "A block is required" unless block

        if time.is_a?(NSDictionary)
          options = time
          time = nil
        elsif time
          options = options.merge(interval: time)
        end

        start(options, &block)
        return self
      end

      def once(options={}, &block)
        raise "A block is required" unless block

        every(options) do |result|
          block.call(result)
          self.stop
        end

        return self
      end

      def convert_queue(queue_name)
        case queue_name
        when :main, nil
          return NSOperationQueue.mainQueue
        when :background
          queue = NSOperationQueue.new
          queue.name = 'com.bubble-wrap.core-motion.background-queue'
          return queue
        when :current
          return NSOperationQueue.currentQueue
        when String
          queue = NSOperationQueue.new
          queue.name = queue_name
          return queue
        else
          queue_name
        end
      end

    end

    class Accelerometer < Generic

      def start(options={}, &handler)
        if options.key?(:interval)
          @manager.accelerometerUpdateInterval = options[:interval]
        end

        if handler
          queue = self.convert_queue(options[:queue])
          @manager.startAccelerometerUpdatesToQueue(queue, withHandler: lambda do |result_data, error|
            handle_result(result_data, error, &handler)
          end)
        else
          @manager.startAccelerometerUpdates
        end

        return self
      end

      def handle_result(result_data, error, &handler)
        if result_data
          result = {
            data: result_data,
            acceleration: result_data.acceleration,
            x: result_data.acceleration.x,
            y: result_data.acceleration.y,
            z: result_data.acceleration.z,
          }
        else
          result = nil
        end

        handler.call(result, error)
      end

      def available?
        @manager.accelerometerAvailable?
      end

      def active?
        @manager.accelerometerActive?
      end

      def data
        @manager.result_data
      end

      def stop
        @manager.stopAccelerometerUpdates
      end

    end

    class Gyroscope < Generic

      def start(options={}, &handler)
        if options.key?(:interval)
          @manager.gyroUpdateInterval = options[:interval]
        end

        if handler
          queue = self.convert_queue(options[:queue])
          @manager.startGyroUpdatesToQueue(queue, withHandler: lambda do |result_data, error|
            handle_result(result_data, error, &handler)
          end)
        else
          @manager.startGyroUpdates
        end

        return self
      end

      def handle_result(result_data, error, &handler)
        if result_data
          result = {
            data: result_data,
            rotation: result_data.rotationRate,
            x: result_data.rotationRate.x,
            y: result_data.rotationRate.y,
            z: result_data.rotationRate.z,
          }
        else
          result = nil
        end

        handler.call(result, error)
      end

      def available?
        @manager.gyroAvailable?
      end

      def active?
        @manager.gyroActive?
      end

      def data
        @manager.gyroData
      end

      def stop
        @manager.stopGyroUpdates
      end

    end

    class Magnetometer < Generic

      def start(options={}, &handler)
        if options.key?(:interval)
          @manager.magnetometerUpdateInterval = options[:interval]
        end

        if options.key?()
        if handler
          queue = self.convert_queue(options[:queue])
          @manager.startMagnetometerUpdatesToQueue(queue, withHandler: lambda do |result_data, error|
            handle_result(result_data, error, &handler)
          end)
        else
          @manager.startMagnetometerUpdates
        end

        return self
      end

      def handle_result(result_data, error, &handler)
        if result_data
          result = {
            data: result_data,
            field: result_data.magneticField,
            x: result_data.magneticField.x,
            y: result_data.magneticField.y,
            z: result_data.magneticField.z,
          }
        else
          result = nil
        end

        handler.call(result, error)
      end

      def available?
        @manager.magnetometerAvailable?
      end

      def active?
        @manager.magnetometerActive?
      end

      def data
        @manager.magnetometerData
      end

      def stop
        @manager.stopMagnetometerUpdates
      end

    end

    class DeviceMotion < Generic

      def start(options={}, &handler)
        if options.key?(:interval)
          @manager.deviceMotionUpdateInterval = options[:interval]
        end

        if options.key?(:reference)
          reference_frame = convert_reference_frame(options[:reference])
        else
          reference_frame = nil
        end

        if handler
          queue = self.convert_queue(options[:queue])

          if reference_frame
            @manager.startDeviceMotionUpdatesUsingReferenceFrame(reference_frame, toQueue: queue, withHandler: lambda do |result_data, error|
              self.handle_result(result_data, error, &handler)
            end)
          else
            @manager.startDeviceMotionUpdatesToQueue(queue, withHandler: lambda do |result_data, error|
              self.handle_result(result_data, error, &handler)
            end)
          end
        else
          if reference_frame
            @manager.startDeviceMotionUpdatesUsingReferenceFrame(reference_frame)
          else
            @manager.startDeviceMotionUpdates
          end
        end

        return self
      end

      def handle_result(result_data, error, &handler)
        if result_data
          result = {
            data: result_data,
            attitude: result_data.attitude,
            rotation: result_data.rotationRate,
            gravity: result_data.gravity,
            acceleration: result_data.userAcceleration,
            magnetic: result_data.magneticField,
          }

          if result_data.attitude
            result.merge!({
              roll: result_data.attitude.roll,
              pitch: result_data.attitude.pitch,
              yaw: result_data.attitude.yaw,
              matrix: result_data.attitude.rotationMatrix,
              quaternion: result_data.attitude.quaternion,
            })
          end

          if result_data.rotationRate
            result.merge!({
              rotation_x: result_data.rotationRate.x,
              rotation_y: result_data.rotationRate.y,
              rotation_z: result_data.rotationRate.z,
            })
          end

          if result_data.gravity
            result.merge!({
              gravity_x: result_data.gravity.x,
              gravity_y: result_data.gravity.y,
              gravity_z: result_data.gravity.z,
            })
          end

          if result_data.userAcceleration
            result.merge!({
              acceleration_x: result_data.userAcceleration.x,
              acceleration_y: result_data.userAcceleration.y,
              acceleration_z: result_data.userAcceleration.z,
            })
          end

          if result_data.magneticField
            case result_data.magneticField.accuracy
            when CMMagneticFieldCalibrationAccuracyLow
              accuracy = :low
            when CMMagneticFieldCalibrationAccuracyMedium
              accuracy = :medium
            when CMMagneticFieldCalibrationAccuracyHigh
              accuracy = :high
            end

            result.merge!({
              field: result_data.magneticField.field,
              magnetic_x: result_data.magneticField.field.x,
              magnetic_y: result_data.magneticField.field.y,
              magnetic_z: result_data.magneticField.field.z,
              magnetic_accuracy: accuracy,
            })
          end
        else
          result = nil
        end

        handler.call(result, error)
      end

      def convert_reference_frame(reference_frame)
        case reference_frame
        when :arbitrary_z
          CMAttitudeReferenceFrameXArbitraryZVertical
        when :corrected_z
          CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
        when :magnetic_north
          CMAttitudeReferenceFrameXMagneticNorthZVertical
        when :true_north
          CMAttitudeReferenceFrameXTrueNorthZVertical
        else
          reference_frame
        end
      end

      def available?
        @manager.deviceMotionAvailable?
      end

      def active?
        @manager.deviceMotionActive?
      end

      def data
        @manager.deviceMotion
      end

      def stop
        @manager.stopDeviceMotionUpdates
      end

    end

    module_function

    def manager
      @manager ||= CMMotionManager.alloc.init
    end

    def accelerometer
    end

    def gyroscope
    end

    def magnetometer
    end

    def device
    end

  end
end
