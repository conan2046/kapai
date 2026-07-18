#include "CSParseBinary_generated.h"

#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>

using namespace flatbuffers;

namespace {

struct ResourceRef {
    std::string property;
    const ResourceData* data;
};

struct DecodedNode {
    const WidgetOptions* widget = nullptr;
    std::vector<ResourceRef> resources;
    std::map<std::string, std::string> strings;
    std::map<std::string, double> numbers;
    std::map<std::string, bool> bools;
};

std::string str(const flatbuffers::String* value) {
    return value ? std::string(value->c_str()) : std::string();
}

void jsonString(std::ostream& out, const std::string& value) {
    out << '"';
    for (unsigned char ch : value) {
        switch (ch) {
            case '"': out << "\\\""; break;
            case '\\': out << "\\\\"; break;
            case '\b': out << "\\b"; break;
            case '\f': out << "\\f"; break;
            case '\n': out << "\\n"; break;
            case '\r': out << "\\r"; break;
            case '\t': out << "\\t"; break;
            default:
                if (ch < 0x20) {
                    out << "\\u" << std::hex << std::setw(4) << std::setfill('0')
                        << static_cast<int>(ch) << std::dec << std::setfill(' ');
                } else {
                    out << static_cast<char>(ch);
                }
        }
    }
    out << '"';
}

std::string sourceType(const std::string& name) {
    if (name == "Panel") return "PanelObjectData";
    if (name == "Button" || name == "TextButton") return "ButtonObjectData";
    if (name == "CheckBox") return "CheckBoxObjectData";
    if (name == "ImageView") return "ImageViewObjectData";
    if (name == "Text" || name == "TextArea" || name == "Label") return "TextObjectData";
    if (name == "TextAtlas" || name == "LabelAtlas") return "TextAtlasObjectData";
    if (name == "TextBMFont" || name == "LabelBMFont") return "TextBMFontObjectData";
    if (name == "TextField") return "TextFieldObjectData";
    if (name == "LoadingBar") return "LoadingBarObjectData";
    if (name == "Slider") return "SliderObjectData";
    if (name == "ScrollView") return "ScrollViewObjectData";
    if (name == "PageView") return "PageViewObjectData";
    if (name == "ListView") return "ListViewObjectData";
    if (name == "Sprite") return "SpriteObjectData";
    if (name == "Particle") return "ParticleObjectData";
    if (name == "ProjectNode") return "ProjectNodeObjectData";
    if (name == "Node" || name == "SingleNode") return "SingleNodeObjectData";
    return name + "ObjectData";
}

void addResource(DecodedNode& out, const char* property, const ResourceData* data) {
    if (data) out.resources.push_back(ResourceRef{property, data});
}

DecodedNode decodeOptions(const std::string& originalClass, const flatbuffers::Table* raw) {
    DecodedNode result;
    std::string name = originalClass;
    if (name == "TextArea" || name == "Label") name = "Text";
    if (name == "TextButton") name = "Button";
    if (name == "LabelAtlas") name = "TextAtlas";
    if (name == "LabelBMFont") name = "TextBMFont";

    if (!raw) return result;
    if (name == "Button") {
        const auto* value = reinterpret_cast<const ButtonOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "NormalFileData", value->normalData());
        addResource(result, "PressedFileData", value->pressedData());
        addResource(result, "DisabledFileData", value->disabledData());
        addResource(result, "FontResource", value->fontResource());
        result.strings["LabelText"] = str(value->text());
        result.strings["FontName"] = str(value->fontName());
        result.numbers["FontSize"] = value->fontSize();
        result.bools["Scale9Enable"] = value->scale9Enabled() != 0;
    } else if (name == "CheckBox") {
        const auto* value = reinterpret_cast<const CheckBoxOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "NormalBackFileData", value->backGroundBoxData());
        addResource(result, "PressedBackFileData", value->backGroundBoxSelectedData());
        addResource(result, "NodeNormalFileData", value->frontCrossData());
        addResource(result, "DisableBackFileData", value->backGroundBoxDisabledData());
        addResource(result, "NodeDisableFileData", value->frontCrossDisabledData());
        result.bools["CheckedState"] = value->selectedState() != 0;
    } else if (name == "ImageView") {
        const auto* value = reinterpret_cast<const ImageViewOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->fileNameData());
        result.bools["Scale9Enable"] = value->scale9Enabled() != 0;
    } else if (name == "Text") {
        const auto* value = reinterpret_cast<const TextOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FontResource", value->fontResource());
        result.strings["LabelText"] = str(value->text());
        result.strings["FontName"] = str(value->fontName());
        result.numbers["FontSize"] = value->fontSize();
        result.numbers["HorizontalAlignmentType"] = value->hAlignment();
        result.numbers["VerticalAlignmentType"] = value->vAlignment();
        result.numbers["AreaWidth"] = value->areaWidth();
        result.numbers["AreaHeight"] = value->areaHeight();
    } else if (name == "TextAtlas") {
        const auto* value = reinterpret_cast<const TextAtlasOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "LabelAtlasFileImage_CNB", value->charMapFileData());
        result.strings["LabelText"] = str(value->stringValue());
        result.strings["StartChar"] = str(value->startCharMap());
        result.numbers["CharWidth"] = value->itemWidth();
        result.numbers["CharHeight"] = value->itemHeight();
    } else if (name == "TextBMFont") {
        const auto* value = reinterpret_cast<const TextBMFontOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->fileNameData());
        result.strings["LabelText"] = str(value->text());
    } else if (name == "TextField") {
        const auto* value = reinterpret_cast<const TextFieldOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FontResource", value->fontResource());
        result.strings["LabelText"] = str(value->text());
        result.strings["PlaceHolderText"] = str(value->placeHolder());
        result.strings["FontName"] = str(value->fontName());
        result.numbers["FontSize"] = value->fontSize();
        result.numbers["MaxLengthText"] = value->maxLength();
        result.bools["PasswordEnable"] = value->passwordEnabled() != 0;
    } else if (name == "LoadingBar") {
        const auto* value = reinterpret_cast<const LoadingBarOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "ImageFileData", value->textureData());
        result.numbers["ProgressInfo"] = value->percent();
        result.numbers["ProgressType"] = value->direction();
    } else if (name == "Slider") {
        const auto* value = reinterpret_cast<const SliderOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "BackGroundData", value->barFileNameData());
        addResource(result, "BallNormalData", value->ballNormalData());
        addResource(result, "BallPressedData", value->ballPressedData());
        addResource(result, "BallDisabledData", value->ballDisabledData());
        addResource(result, "ProgressBarData", value->progressBarData());
        result.numbers["PercentInfo"] = value->percent();
    } else if (name == "Panel") {
        const auto* value = reinterpret_cast<const PanelOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->backGroundImageData());
        result.bools["ClipAble"] = value->clipEnabled() != 0;
        result.bools["Scale9Enable"] = value->backGroundScale9Enabled() != 0;
    } else if (name == "ScrollView") {
        const auto* value = reinterpret_cast<const ScrollViewOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->backGroundImageData());
        result.bools["ClipAble"] = value->clipEnabled() != 0;
        result.bools["BounceEnable"] = value->bounceEnabled() != 0;
        result.numbers["ScrollDirectionType"] = value->direction();
    } else if (name == "PageView") {
        const auto* value = reinterpret_cast<const PageViewOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->backGroundImageData());
        result.bools["ClipAble"] = value->clipEnabled() != 0;
    } else if (name == "ListView") {
        const auto* value = reinterpret_cast<const ListViewOptions*>(raw);
        result.widget = value->widgetOptions();
        addResource(result, "FileData", value->backGroundImageData());
        result.strings["DirectionType"] = str(value->directionType());
        result.strings["HorizontalType"] = str(value->horizontalType());
        result.strings["VerticalType"] = str(value->verticalType());
        result.numbers["ItemMargin"] = value->itemMargin();
        result.bools["BounceEnable"] = value->bounceEnabled() != 0;
    } else if (name == "Sprite") {
        const auto* value = reinterpret_cast<const SpriteOptions*>(raw);
        result.widget = value->nodeOptions();
        addResource(result, "FileData", value->fileNameData());
    } else if (name == "Particle") {
        const auto* value = reinterpret_cast<const ParticleSystemOptions*>(raw);
        result.widget = value->nodeOptions();
        addResource(result, "FileData", value->fileNameData());
    } else if (name == "ProjectNode") {
        const auto* value = reinterpret_cast<const ProjectNodeOptions*>(raw);
        result.widget = value->nodeOptions();
        result.strings["FileName"] = str(value->fileName());
        result.numbers["InnerActionSpeed"] = value->innerActionSpeed();
    } else if (name == "Node" || name == "SingleNode") {
        // NodeReader serializes WidgetOptions directly; SingleNodeOptions is
        // present in the legacy schema but is not used by this Cocos version.
        result.widget = reinterpret_cast<const WidgetOptions*>(raw);
    }
    return result;
}

void writeVec2(std::ostream& out, double x, double y, const char* xName, const char* yName) {
    out << "{\"attributes\":{";
    jsonString(out, xName); out << ':' << x << ',';
    jsonString(out, yName); out << ':' << y << "}}";
}

void writeResource(std::ostream& out, const ResourceRef& ref) {
    const ResourceData* data = ref.data;
    const int type = data ? data->resourceType() : -1;
    out << "{\"nodeName\":\"\",\"nodeType\":\"\",\"property\":";
    jsonString(out, ref.property);
    out << ",\"type\":";
    jsonString(out, type == 1 ? "PlistSubImage" : (type == 0 ? "Normal" : "Default"));
    out << ",\"path\":"; jsonString(out, data ? str(data->path()) : "");
    out << ",\"plist\":"; jsonString(out, data ? str(data->plistFile()) : "");
    out << '}';
}

void writeNode(std::ostream& out, const NodeTree* tree, int& nodeCount,
               std::map<std::string, int>& typeCounts,
               std::vector<ResourceRef>& allResources,
               std::vector<std::string>& unknownClasses) {
    ++nodeCount;
    const std::string className = tree && tree->classname() ? str(tree->classname()) : "Unknown";
    const std::string mappedType = sourceType(className);
    ++typeCounts[mappedType];
    const flatbuffers::Table* raw = nullptr;
    if (tree && tree->options()) raw = tree->options()->data();
    DecodedNode decoded = decodeOptions(className, raw);
    if (!decoded.widget) unknownClasses.push_back(className);
    const WidgetOptions* widget = decoded.widget;

    out << '{';
    out << "\"name\":"; jsonString(out, widget ? str(widget->name()) : "");
    out << ",\"sourceTag\":\"ObjectData\",\"sourceType\":"; jsonString(out, mappedType);
    out << ",\"originalClass\":"; jsonString(out, className);
    out << ",\"actionTag\":" << (widget ? widget->actionTag() : 0);
    out << ",\"tag\":" << (widget ? widget->tag() : 0);
    out << ",\"attributes\":{";
    out << "\"Name\":"; jsonString(out, widget ? str(widget->name()) : "");
    out << ",\"ActionTag\":" << (widget ? widget->actionTag() : 0);
    out << ",\"Tag\":" << (widget ? widget->tag() : 0);
    out << ",\"VisibleForFrame\":" << ((widget && widget->visible()) ? "true" : "false");
    out << ",\"Alpha\":" << (widget ? static_cast<int>(widget->alpha()) : 255);
    out << ",\"ZOrder\":" << (widget ? widget->zOrder() : 0);
    out << ",\"TouchEnable\":" << ((widget && widget->touchEnabled()) ? "true" : "false");
    for (const auto& value : decoded.strings) { out << ','; jsonString(out, value.first); out << ':'; jsonString(out, value.second); }
    for (const auto& value : decoded.numbers) { out << ','; jsonString(out, value.first); out << ':' << value.second; }
    for (const auto& value : decoded.bools) { out << ','; jsonString(out, value.first); out << ':' << (value.second ? "true" : "false"); }
    out << "},\"properties\":{";
    bool first = true;
    auto prop = [&](const char* name) { if (!first) out << ','; first = false; jsonString(out, name); out << ':'; };
    if (widget && widget->size()) { prop("Size"); writeVec2(out, widget->size()->width(), widget->size()->height(), "X", "Y"); }
    if (widget && widget->position()) { prop("Position"); writeVec2(out, widget->position()->x(), widget->position()->y(), "X", "Y"); }
    if (widget && widget->anchorPoint()) { prop("AnchorPoint"); writeVec2(out, widget->anchorPoint()->scaleX(), widget->anchorPoint()->scaleY(), "ScaleX", "ScaleY"); }
    if (widget && widget->scale()) { prop("Scale"); writeVec2(out, widget->scale()->scaleX(), widget->scale()->scaleY(), "ScaleX", "ScaleY"); }
    if (widget && widget->rotationSkew()) { prop("RotationSkew"); writeVec2(out, widget->rotationSkew()->rotationSkewX(), widget->rotationSkew()->rotationSkewY(), "X", "Y"); }
    if (widget && widget->color()) {
        prop("CColor"); out << "{\"attributes\":{\"A\":" << static_cast<int>(widget->color()->a())
            << ",\"R\":" << static_cast<int>(widget->color()->r())
            << ",\"G\":" << static_cast<int>(widget->color()->g())
            << ",\"B\":" << static_cast<int>(widget->color()->b()) << "}}";
    }
    out << "},\"resources\":[";
    for (size_t i = 0; i < decoded.resources.size(); ++i) {
        if (i) out << ',';
        ResourceRef ref = decoded.resources[i];
        allResources.push_back(ref);
        writeResource(out, ref);
    }
    out << "],\"children\":[";
    if (tree && tree->children()) {
        for (flatbuffers::uoffset_t i = 0; i < tree->children()->size(); ++i) {
            if (i) out << ',';
            writeNode(out, tree->children()->Get(i), nodeCount, typeCounts, allResources, unknownClasses);
        }
    }
    out << "]}";
}

void writeEasing(std::ostream& out, const EasingData* easing) {
    out << ",\"easingType\":" << (easing ? easing->type() : 0);
}

void writeFrame(std::ostream& out, const Frame* frame) {
    out << '{';
    if (frame && frame->pointFrame()) {
        const auto* value = frame->pointFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":" << (value->tween() ? "true" : "false");
        out << ",\"x\":" << (value->position() ? value->position()->x() : 0);
        out << ",\"y\":" << (value->position() ? value->position()->y() : 0);
        writeEasing(out, value->easingData());
    } else if (frame && frame->scaleFrame()) {
        const auto* value = frame->scaleFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":" << (value->tween() ? "true" : "false");
        out << ",\"x\":" << (value->scale() ? value->scale()->scaleX() : 0);
        out << ",\"y\":" << (value->scale() ? value->scale()->scaleY() : 0);
        writeEasing(out, value->easingData());
    } else if (frame && frame->colorFrame()) {
        const auto* value = frame->colorFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":" << (value->tween() ? "true" : "false");
        out << ",\"r\":" << (value->color() ? static_cast<int>(value->color()->r()) : 255);
        out << ",\"g\":" << (value->color() ? static_cast<int>(value->color()->g()) : 255);
        out << ",\"b\":" << (value->color() ? static_cast<int>(value->color()->b()) : 255);
        out << ",\"a\":" << (value->color() ? static_cast<int>(value->color()->a()) : 255);
        writeEasing(out, value->easingData());
    } else if (frame && frame->textureFrame()) {
        const auto* value = frame->textureFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":" << (value->tween() ? "true" : "false");
        out << ",\"texture\":"; jsonString(out, value->textureFile() ? str(value->textureFile()->path()) : "");
        out << ",\"plist\":"; jsonString(out, value->textureFile() ? str(value->textureFile()->plistFile()) : "");
        writeEasing(out, value->easingData());
    } else if (frame && frame->eventFrame()) {
        const auto* value = frame->eventFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":false,\"eventName\":";
        jsonString(out, str(value->value()));
        writeEasing(out, value->easingData());
    } else if (frame && frame->intFrame()) {
        const auto* value = frame->intFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":" << (value->tween() ? "true" : "false");
        out << ",\"value\":" << value->value();
        writeEasing(out, value->easingData());
    } else if (frame && frame->boolFrame()) {
        const auto* value = frame->boolFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":false,\"visible\":" << (value->value() ? "true" : "false");
        writeEasing(out, value->easingData());
    } else if (frame && frame->innerActionFrame()) {
        const auto* value = frame->innerActionFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":false,\"innerActionType\":" << value->innerActionType();
        out << ",\"animationName\":"; jsonString(out, str(value->currentAniamtionName()));
        out << ",\"singleFrame\":" << value->singleFrameIndex();
        writeEasing(out, value->easingData());
    } else if (frame && frame->blendFrame()) {
        const auto* value = frame->blendFrame();
        out << "\"frame\":" << value->frameIndex() << ",\"tween\":false";
        writeEasing(out, value->easingData());
    } else {
        out << "\"frame\":0,\"tween\":false";
    }
    out << '}';
}

void writeAnimation(std::ostream& out, const CSParseBinary* root) {
    const NodeAction* action = root ? root->action() : nullptr;
    out << "{\"duration\":" << (action ? action->duration() : 0)
        << ",\"speed\":" << (action ? action->speed() : 1.0)
        << ",\"currentAnimationName\":";
    jsonString(out, action ? str(action->currentAnimationName()) : "");
    out << ",\"timelines\":[";
    if (action && action->timeLines()) {
        for (flatbuffers::uoffset_t i = 0; i < action->timeLines()->size(); ++i) {
            if (i) out << ',';
            const TimeLine* timeline = action->timeLines()->Get(i);
            out << "{\"actionTag\":" << (timeline ? timeline->actionTag() : 0) << ",\"property\":";
            jsonString(out, timeline ? str(timeline->property()) : "");
            out << ",\"frames\":[";
            if (timeline && timeline->frames()) {
                for (flatbuffers::uoffset_t j = 0; j < timeline->frames()->size(); ++j) {
                    if (j) out << ',';
                    writeFrame(out, timeline->frames()->Get(j));
                }
            }
            out << "]}";
        }
    }
    out << "],\"clips\":[";
    if (root && root->animationList()) {
        for (flatbuffers::uoffset_t i = 0; i < root->animationList()->size(); ++i) {
            if (i) out << ',';
            const AnimationInfo* clip = root->animationList()->Get(i);
            out << "{\"name\":"; jsonString(out, clip ? str(clip->name()) : "");
            out << ",\"startFrame\":" << (clip ? clip->startIndex() : 0)
                << ",\"endFrame\":" << (clip ? clip->endIndex() : 0) << '}';
        }
    }
    out << "]}";
}

bool readFile(const char* path, std::vector<unsigned char>& data) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input) return false;
    const std::streamsize size = input.tellg();
    if (size <= 0) return false;
    input.seekg(0, std::ios::beg);
    data.resize(static_cast<size_t>(size));
    return static_cast<bool>(input.read(reinterpret_cast<char*>(data.data()), size));
}

}  // namespace

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "Usage: csb_dump <input.csb> <output.json>\n";
        return 2;
    }
    std::vector<unsigned char> data;
    if (!readFile(argv[1], data)) {
        std::cerr << "Unable to read " << argv[1] << '\n';
        return 3;
    }
    // Cocos Studio stores class-specific option tables behind Options.data,
    // while the legacy schema declares that slot as a generic table. The
    // generated whole-buffer verifier follows the declared WidgetOptions
    // layout and is therefore unsafe for valid class-specific CSBs. This is
    // the same reason CSLoader reads the root directly and dispatches by
    // classname before casting Options.data.
    if (data.size() < sizeof(flatbuffers::uoffset_t)) return 4;
    const CSParseBinary* root = GetCSParseBinary(data.data());
    if (!root || !root->nodeTree()) return 4;
    std::ofstream output(argv[2], std::ios::binary);
    if (!output) return 5;

    int nodeCount = 0;
    std::map<std::string, int> typeCounts;
    std::vector<ResourceRef> resources;
    std::vector<std::string> unknownClasses;
    output << "{\"schemaVersion\":1,\"kind\":\"CocosStudioBinaryUI\",\"sourceVersion\":";
    jsonString(output, root && root->version() ? str(root->version()) : "");
    output << ",\"coordinateSystem\":{\"origin\":\"bottom-left\",\"xAxis\":\"right\",\"yAxis\":\"up\",\"unit\":\"pixel\"}";
    output << ",\"root\":";
    writeNode(output, root->nodeTree(), nodeCount, typeCounts, resources, unknownClasses);
    output << ",\"animation\":";
    writeAnimation(output, root);
    output << ",\"statistics\":{\"nodeCount\":" << nodeCount << ",\"nodeTypes\":{";
    bool first = true;
    for (const auto& item : typeCounts) { if (!first) output << ','; first = false; jsonString(output, item.first); output << ':' << item.second; }
    output << "},\"resourceReferenceCount\":" << resources.size() << ",\"unknownClasses\":[";
    for (size_t i = 0; i < unknownClasses.size(); ++i) { if (i) output << ','; jsonString(output, unknownClasses[i]); }
    output << "]}}\n";
    return 0;
}
