import UIKit
import MetalKit

let vertexData: [Float] = [-1, -1, 0, 1,
                            1, -1, 0, 1,
                           -1,  1, 0, 1,
                            1,  1, 0, 1]

let textureCoordinateData: [Float] = [0, 1,
                                      1, 1,
                                      0, 0,
                                      1, 0]

class ViewController: UIViewController, MTKViewDelegate {

    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var texture: MTLTexture!

    private var vertexBuffer: MTLBuffer!
    private var texCoordBuffer: MTLBuffer!

    private var computePipeline: MTLComputePipelineState!

    @IBOutlet private weak var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMetal()

        loadTexture()

        makePipeline(pixelFormat: texture.pixelFormat)

        mtkView.enableSetNeedsDisplay = true
        mtkView.setNeedsDisplay()
    }

    private func setupMetal() {
        commandQueue = device.makeCommandQueue()

        mtkView.device = device
        mtkView.delegate = self
        mtkView.framebufferOnly = false
    }

    private func makePipeline(pixelFormat: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else {fatalError()}

        let function = library.makeFunction(name: "computeShader")!
        computePipeline = try! device.makeComputePipelineState(function: function)
    }

    private func loadTexture() {
        let textureLoader = MTKTextureLoader(device: device)
        texture = try! textureLoader.newTexture(
            name: "kerokero",
            scaleFactor: view.contentScaleFactor,
            bundle: nil)

        mtkView.colorPixelFormat = texture.pixelFormat
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // nop
    }

    func draw(in view: MTKView) {

        guard let drawable = view.currentDrawable else {return}

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}

        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        guard let computePipeline = computePipeline else {fatalError()}
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setTexture(drawable.texture, index: 1)

        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        let threadgroupSize = MTLSizeMake(w, h, 1)

        let threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid,
                                       threadsPerThreadgroup: threadgroupSize)

        computeEncoder.endEncoding()

        commandBuffer.present(drawable)

        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()
    }
}

